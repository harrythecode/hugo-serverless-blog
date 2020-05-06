---
title : "AWSのコストをSlackに通知する【Lambda - (2)STS編】"
date  : 2020-03-21T12:36:44+01:00
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
meta_image  : "/thumbnails/2020-03-21-aws-cost-sts.png"
description : ""
---

「[AWSのコストをSlackに通知する](/categories/slackコスト通知/)」シリーズです。

- [AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】](/posts/2020/03/21/aws-cost/)
- AWSのコストをSlackに通知する【Lambda - (2)STS編】
- [AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】](/posts/2020/03/22/cli-lambda/)
- [AWSのコストをSlackに通知する【Lambda - (4)Lambda実装編】](/posts/2020/03/22/cost-lambda/)

前回記事ではIAMを作成しました。

# おさらい

Lambdaを使って、CloudWatch MetricsからAWSのコストを取得するためには下記のステップを踏みます。

{{<figure src="/images/2020/03-21-aws-cost-sts-01.png">}}

- (1) Lambda実行用のIAMロールを付与し、Lambdaを実行する
- (2) STSを用いてコスト取得用のIAMロールにスイッチする
- (3) CostExplorerからコスト情報がLambdaへと返される

前回記事では(1)用のIAMを作成したので、次は(2)のSTS用のIAMロールを作成します。

## (1) STS(Security Service Token)用のIAMロールの作成

まずはSTSに使用するIAMロールの作成から。

本記事では「`aws-cost-monitoring-metrics`」ロールを作成し、以下の手順を実行します。


### 信頼されたエンティティ

{{< figure src="/images/2020/03-21-aws-cost-sts-02.png" >}}

{{< figure src="/images/2020/03-21-aws-cost-sts-03.png" >}}

- 現アカウントの全てのIAMユーザ/ロールからの「sts:AssumeRole」の実行を許可する。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<あなたのAWSアカウントID>:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

>「arn:aws:iam::xxx:root」はそのアカウント上(xxx)の全てのIAMユーザ及びロールを示します。
> 詳しく知りたい方は公式ドキュメント[AWS JSON ポリシーの要素: Principal](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference_policies_elements_principal.html)を読んでください。

### 実行ポリシー

{{< figure src="/images/2020/03-21-aws-cost-sts-04.png" >}}

- cloudwatchからメトリクスを取得できる権限を付与する

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowGetCost",
            "Effect": "Allow",
            "Action": "cloudwatch:GetMetricData",
            "Resource": "*"
        }
    ]
}
```

今回は以上です。次回は、いよいよ「(3) Lambda」偏です。
