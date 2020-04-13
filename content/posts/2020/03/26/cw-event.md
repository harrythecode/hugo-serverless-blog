---
title : "AWSのコストをSlackに通知する【Cloudwatch/SNS編】"
date  : 2020-03-26T16:40:10Z
draft : false
tags  : [
    "aws",
    "lambda",
    "sns",
    "cloudwatch",
]
categories: [
    "AWS",
    "サーバレス技術"
]
meta_image  : "/thumbnails/2020-03-26-cw-event.png"
description : ""
---

今回はCloudwatch Eventsを作成して、Lambdaを定期実行させ、失敗時のSNSトピックを作成します。

# おさらい

{{<figure src="/images/2020/03-21-aws-cost-01.png" >}}

②は完成したので今回は①、③を終わらせます。

- [ ] ①Cloudwatch Events: Lambdaを定期実行(毎朝7時)
- [x] ②Lambda: Lambda実行用のIAMロールを作成 -> STS(Security Service Token) ->CW Metricsでコスト取得 -> Slackに通知する
- [ ] ③SNS: 失敗時はSNSへ通知

## ②Lambda編
1. [AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】](https://amezou.com/posts/2020/03/21/aws-cost/)
2. [AWSのコストをSlackに通知する【Lambda - (2)STS編】](https://amezou.com/posts/2020/03/21/aws-cost-sts/)
3. [AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】](https://amezou.com/posts/2020/03/22/cli-lambda/)
4. [AWSのコストをSlackに通知する【Lambda - (4)Lambda実装編】](https://amezou.com/posts/2020/03/22/cost-lambda/)

# Cloudwatch Events: Lambdaを定期実行

1. 定期実行させるLambdaへアクセス。
{{<figure src="/images/2020/03-26-cw-event-01.png" >}}

2. ルールを作成
{{<figure src="/images/2020/03-26-cw-event-02.png" >}}

> ルールタイプはスケジュール式をオススメします。次の公式ドキュメントが参考になります👉[Rate または Cron を使用したスケジュール式](https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/services-cloudwatchevents-expressions.html)

3. きちんと作成されてますね！
{{<figure src="/images/2020/03-26-cw-event-03.png" >}}

# SNS: 失敗時はSNSへ通知
## SNSトピックの作成
まずは失敗時に通知するようのSNSトピックを作成しましょう。

1. SNSコンソールへアクセスし、トピックの作成をクリック。
{{<figure src="/images/2020/03-26-cw-event-04.png" >}}

> 自分自身が作成したLambda関数と同じリージョンにSNSトピックを作成してください。LambdaとSNSは同じリージョンでないと関連付けできません。

2. 適当な名前を入力してトピックを作成。オプションは変更せずにそのまま作成で良いです。
{{<figure src="/images/2020/03-26-cw-event-05.png" >}}
{{<figure src="/images/2020/03-26-cw-event-06.png" >}}

3. サブスクリプションを作成します。今回は自分のEMAILに通知するようにします。
{{<figure src="/images/2020/03-26-cw-event-07.png" >}}
{{<figure src="/images/2020/03-26-cw-event-08.png" >}}

4. 確認メールが届くので、"Confirm subscription"をクリックします。
{{<figure src="/images/2020/03-26-cw-event-09.png" >}}
{{<figure src="/images/2020/03-26-cw-event-10.png" >}}

5. SNSトピック上で「確認済み」となってますね！
{{<figure src="/images/2020/03-26-cw-event-11.png" >}}

## LambdaにSNSトピックをつける

1. Lambdaコンソールへアクセスします。

2. 少し下へスクロールすると「非同期呼び出し」の項目があるので「編集」をクリック
{{<figure src="/images/2020/03-26-cw-event-12.png" >}}

3. デッドレターキューにおいて先ほど作成したSNSトピックを選択し、保存すれば完成！
{{<figure src="/images/2020/03-26-cw-event-13.png" >}}
{{<figure src="/images/2020/03-26-cw-event-14.png" >}}

4. きちんと反映されてますね！
{{<figure src="/images/2020/03-26-cw-event-15.png" >}}

# 完成品
毎日こんな感じで報告がきます。

{{<figure src="/images/2020/03-26-cw-event-16.png" >}}
