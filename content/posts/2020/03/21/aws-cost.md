---
title : "AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】"
date  : 2020-03-21T09:15:49+01:00
draft : false
tags  : [
    "aws",
    "lambda",
    "sns",
    "cloudwatch",
]
categories: [
    "AWS",
    "サーバレス技術",
    "Slackコスト通知"
]
meta_image  : "/thumbnails/2020-03-21-aws-cost.png"
description : ""
---

「[AWSのコストをSlackに通知する](/categories/slackコスト通知/)」シリーズです。

- AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】
- [AWSのコストをSlackに通知する【Lambda - (2)STS編】](/posts/2020/03/21/aws-cost-sts/)
- [AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】](/posts/2020/03/22/cli-lambda/)
- [AWSのコストをSlackに通知する【Lambda - (4)Lambda実装編】](/posts/2020/03/22/cost-lambda/)

今回は下記のような仕組みを使います。

{{< figure src="/images/2020/03-21-aws-cost-01.png" >}}

- ①Cloudwatch Events: Lambdaを定期実行(毎朝8時)
- ②Lambda: Lambda実行用のIAMロールを作成 -> STS(Security Service Token) ->CW Metricsでコスト取得 -> Slackに通知する
- ③SNS: 失敗時はSNSへ通知

取り掛かる順番としては、②→③→①です。

# 他に選択肢はないのか？
色々なやり方があります。例えば以下の通り

- Cloudwatch Alarmで一定金額を超えたら通知
- STSの代わりに「Access/Secret Key」を持たせてCW Metricsを実行
- そもそも失敗時の通知はいらない
- LambdaにCloudwatch Metricsを取得できるようにすればSTS不要では

## Cloudwatch Alarmで一定金額を超えたら通知
この方法がAWS初心者にはオススメです。と言うのもこれから話す内容は、LambdaやAWSのセキュリティ作法が詳しくないと難しいです。

気になる人はAWSのドキュメント「[AWS の予想請求額をモニタリングする請求アラームの作成](https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html)」をご覧ください。

**追記(2020-03-21 14:24 UTC+1):** どうやらCloudwatch上で請求書の金額を参照するには、上記のアラームを作成する必要があります。僕は下記のように作成しました。

{{< figure src="/images/2020/03-21-aws-cost-11.png" >}}

## STSの代わりに「Access/Secret Key」を持たせてCW Metricsを実行
AWS初心者の方は「色々と面倒だから「Access/Secret Key」をLambdaに持たせれば良いや」と考えがちなのですが、絶対に辞めましょう。

と言うのもAPIキーが漏洩した時のリスクを考えてないからです。

AWS上の「Access/Secret Key」は、与えられる権限に応じたコンソール上の操作ができると覚えてください。

本当にどうしても使いたい、と言う場合は次の２点を守りましょう。

1. 必要最小権限を与える(管理者権限は絶対にNG)
2. 定期的に「Access/Secret Key」を変更する

じゃあ、STS(Security Service Token)は何なのか、と言うとこいつは特定のIAMロール/ユーザに「一時的」にスイッチできる「Access/Secret Key」を発行する役割があります。上記の「2」をLambdaを実行する度に行うもの、と考えてもらえれば良いです。

## そもそも失敗時の通知はいらない
確かに失敗時の通知は今回は省略できます。と言うのも毎朝8時にAWSの請求金額を見ることになるので、その通知がない場合は「何か起きた」と言うことが分かります。

ただ１つ覚えてもらいたいのが、実務ではそう言った「マニュアル作業」は極力省略していきます。

と言うのも「毎朝通知が来る」と言うのはあなたにとっては当たり前の常識かもしれませんが、他のメンバーにとっては「当たり前」ではないからです。

そう言った小さな「仕事の属人化」を避けることで、毎日の仕事が楽になっていきます。(辞める時の引継ぎも楽ですよ！)

## LambdaにCloudwatch Metricsを取得できるようにすればSTS不要では
全てのリソースが１つのアカウントに存在する場合は、STSは不要です。

STSの利点としては、複数アカウントを管理している際に、例えばアカウントAで支払いをし、アカウントBでLambdaを実装するのような「クロスアカウント」の場合に有効です。

今回の実装は少し複雑ですが、大きな会社であれば、実務レベルでこのような実装が求められる場合は多いと考えられます。

と言うのも1社で1つのAWSアカウントだけを扱う、と言うのは結構珍しいケースだから、です。

この際に、少し難し目の手法を学んで周りと差をつけちゃいましょう！

では早速、実装に移ります。

# Lambdaの実装
ここでやることをもう1度おさらいします。

- Lambda:
  - (1) Lambda実行用のIAMロールを作成
  - (2) STS(Security Service Token)
  - (3) CW Metricsでコスト取得
  - (4) Slackに通知する

結構ボリューミーですね。

とりあえずLambdaの作成から取り掛かりましょう。

## (1) Lambda実行用のIAMロールを作成

まずはLambdaに使用するIAMロールの作成から。

本記事では「`aws-cost-monitoring-lambda`」ロールを作成し、以下の手順を実行します。

### 信頼されたエンティティの条件

{{< figure src="/images/2020/03-21-aws-cost-02.png" >}}

{{< figure src="/images/2020/03-21-aws-cost-03.png" >}}

- lambda.amazonaws.com上で「sts:AssumeRole」の実行を許可する。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### 実行ポリシー

{{< figure src="/images/2020/03-21-aws-cost-04.png" >}}

- 現アカウント上の全てのLambdaを実行できるようにする (Cloudwatch Logsへのアクセス権限、AssumeRole、デッドキューレター用のSNS Publishも可能にさせます。)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "AllowBasicLambdaFeature",
          "Effect": "Allow",
          "Action": [
              "sts:AssumeRole",
              "sns:Publish",
              "logs:PutLogEvents",
              "logs:CreateLogStream",
              "logs:CreateLogGroup",
              "lambda:InvokeFunction"
          ],
          "Resource": "*"
        }
    ]
}
```

> 業務であればLambdaごとにIAMロールを作成することをオススメします。
> と言うのも各Lambdaごとに必要な権限が違うので、それぞれに必要な権限を与えるべきです。
> 今回は今後の手順を省略するために"あえて"全てのLambdaを実行できるよう許可しています。

### 動作確認
適当にLambdaを作って、上記のIAMロールで実行できるかどうかを確認します。

1. Lambda新規作成
{{< figure src="/images/2020/03-21-aws-cost-05.png">}}

2. 作成したIAMロールを使う
{{< figure src="/images/2020/03-21-aws-cost-06.png">}}

3. 自動でHelloメッセージが作られる
{{< figure src="/images/2020/03-21-aws-cost-07.png">}}

4. 「アクション」横のタブからテストイベントを作成
{{< figure src="/images/2020/03-21-aws-cost-08.png">}}

5. helloWorldイベントを作成
{{< figure src="/images/2020/03-21-aws-cost-09.png">}}

6. 「テスト」ボタンをクリックし、成功が出ることを確認
{{< figure src="/images/2020/03-21-aws-cost-10.png">}}

今回は以上です。次回は[「(2) STS(Security Service Token)」偏](https://amezou.com/posts/2020/03/21/aws-cost-sts/)です。
