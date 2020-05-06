---
title : "AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】"
date  : 2020-03-22T15:58:24+01:00
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
meta_image  : "/thumbnails/2020-03-22-cli-lambda.png"
description : ""
---

「[AWSのコストをSlackに通知する](/categories/slackコスト通知/)」シリーズです。

- [AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】](/posts/2020/03/21/aws-cost/)
- [AWSのコストをSlackに通知する【Lambda - (2)STS編】](/posts/2020/03/21/aws-cost-sts/)
- AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】
- [AWSのコストをSlackに通知する【Lambda - (4)Lambda実装編】](/posts/2020/03/22/cost-lambda/)

今回はLambdaを実装するに当たって、更に開発スピードを上げるためのコツについて解説します。クラウドエンジニアを目指している方は必見の情報なのでぜひ挑戦してみてください！

# おさらい

Lambdaを使って、CloudWatch MetricsからAWSのコストを取得するためには下記のステップを踏みます。

{{<figure src="/images/2020/03-21-aws-cost-sts-01.png">}}

- (1) Lambda実行用のIAMロールを付与し、Lambdaを実行する
- (2) STSを用いてコスト取得用のIAMロールにスイッチする
- (3) Cloudwatch Metricsからコスト情報がLambdaへと返される

(1), (2)に必要なIAMロールは既に作成しています。

## Lambdaで使用するCloudwatch Metricsの確認

Lambdaを用いてAWSのサービスを実行する際には下記の手順がオススメです。

- AWS CLIで実際に試してみる
- AWS SDKのドキュメントを読む
- 実際にLambdaに実装をする

理由としては、いきなりLambdaを実装しながらあれこれ試すよりも、簡単に動作確認を先にした方が、後の実装でかなり理解度が高まり、開発のスピードアップにつながります。

Lambdaを何度も実行して動作確認するのも良いですが、時間が掛かる上に、何より出力結果がとても見辛いんです。

### AWS CLIで実際に試してみる

[AWS CLI Command Reference - get-metric-data](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/get-metric-data.html)

{{<figure src="/images/2020/03-22-cli-lambda-01.png">}}

「AWS CLI コマンド名」で調べると上記のようなAWSの<cite>CLI[^1]</cite>のドキュメントが出てきます。

更に忘れてはいけないのがそのコマンドも実際にAWS上で使われているものを利用すると言うこと。

例えばAWSの請求アラームを作成する際に次のような画面が出てきます。

{{<figure src="/images/2020/03-22-cli-lambda-03.png">}}

この画像の意味するところは、請求データを「バージニア北部(us-east-1)リージョン」に保存しますよ、と言うもの。

>【AWSでハマりやすい罠】対象のデータがどのリージョンにあるのかを確認せずに使ってしまう。

Cloudwatch Metricsのデータを取得する「[get-metric-data](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/get-metric-data.html)」に戻りましょう。

下記の「Synopsis」ではそのコマンドで必要な引数を教えてくれます。この場合「`metric-data-queries, start-time, end-time`」を必ずコマンド実行に渡さなければいけません。

{{<figure src="/images/2020/03-22-cli-lambda-02.png" title="get-metric-dataの引数">}}

ただどうも調べると「`cli-input-json`」オプションで必要な引数をJSONファイルにして渡せるみたいなので、今回はそちらを利用します。色々と調べた結果、次のようなJSONファイルを作成しました。

- test.json

```json
{
    "MetricDataQueries": [
        {
            "Id": "monitoringAwsCostPerDay",
            "MetricStat": {
                "Metric": {
                    "Namespace": "AWS/Billing",
                    "MetricName": "EstimatedCharges",
                    "Dimensions": [
                        {
                            "Name": "Currency",
                            "Value": "USD"
                        }
                    ]
                },
                "Period": 86400,
                "Stat": "Maximum"
            }
        }
    ],
    "StartTime": "2020-03-22T00:00:0000",
    "EndTime": "2020-03-23T00:00:0000"
}
```

> Periodはメトリクス上の期間を表します。AWSのコストは一日単位で変動するので1日(86400秒)を指定してます。

> ドキュメントによると、Periodを例えば5分としたら「EndTime」は「12:09」よりも「12:05」のようにキリのいい数字の方がパフォーマンスが上がるそうです。
> 今回のPeriodは一日としたので「StartTime」と「EndTime」は一日の差をあけています。

「StartTime, EndTime」は「start-time, end-time」オプションに該当し、「MetricDataQueries」は「metric-data-queries」オプションに該当します。そして疑問なのが「MetricDataQueries」にどんな値を指定すれば良いのか、と言うもの。

今回は「generate-cli-skeleton」オプションがサンプルのJSONフォーマットを表示してくれます。

- `$ aws cloudwatch get-metric-data --generate-cli-skeleton`
```json
{
    "MetricDataQueries": [
        {
            "Id": "",
            "MetricStat": {
                "Metric": {
                    "Namespace": "",
                    "MetricName": "",
                    "Dimensions": [
                        {
                            "Name": "",
                            "Value": ""
                        }
                    ]
                },
                "Period": 0,
                "Stat": "",
                "Unit": "Bits"
            },
            "Expression": "",
            "Label": "",
            "ReturnData": true,
            "Period": 0
        }
    ],
    "StartTime": "1970-01-01T00:00:00",
    "EndTime": "1970-01-01T00:00:00",
    "NextToken": "",
    "ScanBy": "TimestampDescending",
    "MaxDatapoints": 0
}
```

フォーマットは分かったので何のデータを入力すれば良いのかを確認しましょう。

#### AWS CLIの引数に迷った際はコンソール👉「list」系コマンドの順で確認しよう

AWS CLIを実行すると言ってもコンソールにある情報をただ単にテキストとして扱うだけです。なので対象のサービスのコンソールへアクセスしましょう。

[CloudWatch Metrics - us-east-1リージョン](https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph=~())

1. 請求メトリクスを選択
{{<figure src="/images/2020/03-22-cli-lambda-04.png">}}

2. 概算合計を選択
{{<figure src="/images/2020/03-22-cli-lambda-05.png">}}

3. 対象のメトリクス「EstimatedCharges」を選択するとグラフ化されます。
{{<figure src="/images/2020/03-22-cli-lambda-06.png">}}

4. ベルマークを押します
{{<figure src="/images/2020/03-22-cli-lambda-07.png">}}

5. 何とここにはメトリクスに必要な情報が表記されてます。
{{<figure src="/images/2020/03-22-cli-lambda-08.png">}}

更に、Cloudwatchではデータが保存されるデータをリスト化できる「[list-metrics](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/list-metrics.html)」があります。

こいつを次のように実行します。**リージョンは必ず"us-east-1"を選択しましょう！**

- `$ aws cloudwatch list-metrics --namespace AWS/Billing --region us-east-1`
```
{
    "Metrics": [
        {
            "Namespace": "AWS/Billing",
            "MetricName": "EstimatedCharges",
            "Dimensions": [
                {
                    "Name": "ServiceName",
                    "Value": "AWSDataTransfer"
                },
                {
                    "Name": "Currency",
                    "Value": "USD"
                }
            ]
        },
        ...
        {
            "Namespace": "AWS/Billing",
            "MetricName": "EstimatedCharges",
            "Dimensions": [
                {
                    "Name": "Currency",
                    "Value": "USD"
                }
            ]
        }
    ]
}
```

コンソールの情報と、CLIの結果を合わせると次のことが分かります。

- Namespace(名前空間): AWS/Billing
- MetricName(メトリクス名): EstimatedCharges
- Dimensions: name=Currency, value=USD

上記のパラメータを使えば良さそうですね！

- `$ aws cloudwatch get-metric-data --cli-input-json file://<your-path-to>/test.json --region us-east-1`
```json
{
    "MetricDataResults": [
        {
            "Id": "monitoringAwsCostPerDay",
            "Label": "EstimatedCharges",
            "Timestamps": [
                "2020-03-22T00:00:00Z"
            ],
            "Values": [
                0.64
            ],
            "StatusCode": "Complete"
        }
    ],
    "Messages": []
}
```

この「AWSのコンソール👉list系のコマンド」の順で確認する手法は、他のAWSサービスでも使えます。かなり有用な手法なので、Lambdaを作成する前にはぜひ確認しましょう。

次こそはLambdaを実装していきます。

[^1]: Command Line Interface; あなたのパソコンからAWSのサービスを呼び出すことが可能なツール
