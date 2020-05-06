---
title : "AWSのコストをSlackに通知する【Lambda - (4)Lambda実装編】"
date  : 2020-03-22T16:50:52+01:00
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
meta_image  : "/thumbnails/2020-03-22-cost-lambda.png"
description : ""
---

「[AWSのコストをSlackに通知する](/categories/slackコスト通知/)」シリーズです。

- [AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】](/posts/2020/03/21/aws-cost/)
- [AWSのコストをSlackに通知する【Lambda - (2)STS編】](/posts/2020/03/21/aws-cost-sts/)
- [AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】](/posts/2020/03/22/cli-lambda/)
- AWSのコストをSlackに通知する【Lambda - (4)Lambda実装編】

前回の記事ではLambdaで実行するコマンドの確認を行いました。今回は実際に下記通り実装を進めていきます。

# Lambdaの概要
- 言語: Nodejs 12.x
- 名前: monitoringAwsCost
- 実行IAMロール: aws-cost-monitoring ([AWSのコストをSlackに通知する【Lambda - (1)IAM作成編】](https://amezou.com/posts/2020/03/21/aws-cost/)で作成済み)

何かを実装する前には、何を実現したいのかコメントを書きましょう。こうすることで実装中に余計なことを考えずに、その指示にしたがってひたすらコードを書くだけで良くなります。

```
# Lambda内でやりたいこと
# 1. STSを利用して特定のIAMロールにスイッチ
# 2. Cloudwatch Metricsでコスト取得
# 3. 取得したデータをSlackで綺麗に表示されるようフォーマット
# 4. Slackに通知
```

今回は「[AWS Javascript SDK - getMetricData](https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/CloudWatch.html#getMetricData-property)」を参考にしながら開発を進めます。

## 準備編
今回のフォルダ構成は下記の通りです。

```
lambda_scripts/
├── Makefile
├── functions
│   └── monitoringAwsCost
│       ├── helper-functions.js
│       ├── index.js
│       ├── node_modules
│       └── package-lock.json (自動生成)
└── project.json
```

- `$ npm install moment` で、[moment](https://www.npmjs.com/package/moment)をインストール。
- `$ npm install @slack/webhook` で、[@slack/webhook](https://www.npmjs.com/package/@slack/webhook)をインストール。
- Apexを使ってLambdaを管理 [ApexでAWS Lambdaファンクションを管理する](https://dev.classmethod.jp/articles/how-to-manage-aws-lambda-functions-with-apex/)

> monitoringAwsCost配下のファイル全て(monitoringAwsCostフォルダを除く)を「monitoringAwsCost.zip」ファイルにして直接Lambdaにアップロードすることも可能。

## まずは完成品から

- helper-function.js
```js
const AWS = require('aws-sdk')
const sts = new AWS.STS({region: 'us-east-1'});

const getCrossAccountCredentials = async (role_arn) => {
  return new Promise((resolve, reject) => {
    const timestamp = (new Date()).getTime();
    const params    = {
      RoleArn: role_arn,
      RoleSessionName: `aws-cost-monitoring-${timestamp}`,
    };
    sts.assumeRole(params, (err, data) => {
      if (err) reject(err);
      else {
        resolve({
          accessKeyId: data.Credentials.AccessKeyId,
          secretAccessKey: data.Credentials.SecretAccessKey,
          sessionToken: data.Credentials.SessionToken,
        });
      }
    });
  });
}

module.exports = {
    getCrossAccountCredentials
}
```

- index.js
```js
/***
 * Enviroment Variables
 */
const target_date   = process.env.TARGET_DATE;   // optional
const role_arn      = process.env.ROLE_ARN;      // required
const slack_webhook = process.env.SLACK_WEBHOOK; // required

/***
 * Load Modules
 */
const AWS    = require('aws-sdk');
const moment = require('moment');
const helper_func = require('./helper-functions');
const { IncomingWebhook } = require('@slack/webhook');

/***
 * Global Variables
 */
const webhook   = new IncomingWebhook(slack_webhook);
const today     = moment(target_date).utc().startOf('day')
const tomorrow  = moment(today).add(1, 'days');
const formatted_today    = today.toISOString();
const formatted_tomorrow = tomorrow.toISOString();

console.log(formatted_today, formatted_tomorrow);

exports.handle = async function(event) {
    // What to do?
    // 1. Switch role to a specific IAM role via STS
    // Cloudwatch data is only in the us-east-1 region.
    const accessparams     = await helper_func.getCrossAccountCredentials(role_arn);
    accessparams["region"] = 'us-east-1';

    // Assuming the new role will return temporary credentials
    const cloudwatch_client = new AWS.CloudWatch(accessparams);

    // 2. Pull Cost Data from Cloudwatch Metrics
    // Define parameters
    const cw_params = {
      MetricDataQueries: [
        {
          Id: 'monitoringAwsCostPerDay',
          MetricStat: {
            Metric: {
              Namespace  : 'AWS/Billing',
              MetricName : 'EstimatedCharges',
              Dimensions : [
                {
                  Name: 'Currency',
                  Value: 'USD'
                }
              ]
            },
            Period: 86400,
            Stat: 'Maximum',
          }
        },
      ],
      StartTime : formatted_today,
      EndTime   : formatted_tomorrow,
    };
    const metric_data = await getMericDataFromCloudWatch(cloudwatch_client, cw_params);

    if(metric_data) {
      // 3. Formatting for Slack
      // 4. Send Slack
      const usd_cost = metric_data.MetricDataResults[0].Values[0];

      console.log(usd_cost);

      await webhook.send({
          text    : `${formatted_today}時点の金額は下記の通りです。`,
          channel : "#aws-notifications",
          attachments: [{"text": `Total Cost: ${usd_cost}$`}]
      });
    }

    return true;
}

async function getMericDataFromCloudWatch(cloudwatch_client, cw_params) {

  console.log("Query: ", cw_params)

  var ret = await new Promise(function(resolve, reject) {
    cloudwatch_client.getMetricData(cw_params, async function(err, result) {
      if (err) {
          console.log(err, err.stack);
          reject("Internal server error.")
      } else {
          console.log(result);
          resolve(result)
      }})
  });

  console.log("Ret: ", ret)

  return ret
}
```

### 手動でアップロードする際の注意
- `$ npm install moment` で、[moment](https://www.npmjs.com/package/moment)をインストール。
- `$ npm install @slack/webhook` で、[@slack/webhook](https://www.npmjs.com/package/@slack/webhook)をインストール。
- monitoringAwsCost配下のファイル全て(monitoringAwsCostフォルダを除く)を「monitoringAwsCost.zip」ファイルにして直接Lambdaにアップロードする。
- 「1.」のハンドラ名を「index.handle」に変更。(Apexを使うとこれがデフォルトになるみたいです。)
{{<figure src="/images/2020/03-22-cost-lambda-01.png" title="上手くアップロードできれば2.のようになります">}}

- 環境変数には下記の通り値を入力
  - ROLE_ARN: 次の手順で作成したIAMロールのARNを入力👉[AWSのコストをSlackに通知する【Lambda - (2)STS編】](https://amezou.com/posts/2020/03/21/aws-cost-sts/)
  - SLACK_WEBHOOK: SlackのWebhook URLを入力(参考情報「[slackのIncoming webhookが新しくなっていたのでまとめてみた](https://qiita.com/kshibata101/items/0e13c420080a993c5d16)」)

{{<figure src="/images/2020/03-22-cost-lambda-02.png">}}
# コードの解説

```
# Lambda内でやりたいこと
# 1. STSを利用して特定のIAMロールにスイッチ
# 2. Cloudwatch Metricsでコスト取得
# 3. 取得したデータをSlackで綺麗に表示されるようフォーマット
# 4. Slackに通知
```

## Momentで今日と昨日の日付を取得

```js
/***
 * Global Variables
 */
const today     = moment(target_date).utc().startOf('day')
const tomorrow  = moment(today).add(1, 'days');
const formatted_today    = today.toISOString();
const formatted_tomorrow = tomorrow.toISOString();
// 2020-03-22T00:00:00.000Z 2020-03-23T00:00:00.000Z
```

> CloudwatchのGetMetricDataでは「StartTime, EndTime」において、ISOStringフォーマット、Unix時間及びDateオブジェクトのみを受け取るようです。これが意外と罠でした。

## 1. STSを利用して特定のIAMロールにスイッチ

[using profile that assume role in aws-sdk (AWS JavaScript SDK)](https://stackoverflow.com/a/55315086)でクロスアカウント用のSTSの手法が紹介されてたので採用。もちろん同一アカウント内のSTSにも利用可能です。

とりあえずこの実装は別のLambdaでも使うかもしれないのでヘルパー機能として別ファイルに定義しています。

## 2. Cloudwatch Metricsでコスト取得
公式ドキュメント「[AWS Javascript SDK - getMetricData](https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/CloudWatch.html#getMetricData-property)」を見ながら実装しました。Cloudwatchクライアントを作成時に「us-east-1」を必ず指定しましょう。

```js
// 1. Switch role to a specific IAM role via STS
// Cloudwatch data is only in the us-east-1 region.
const accessparams     = await helper_func.getCrossAccountCredentials(role_arn);
accessparams["region"] = 'us-east-1';
```

## 3. 取得したデータをSlackで綺麗に表示されるようフォーマット

前回の[AWSのコストをSlackに通知する【Lambda - (3)Lambda準備編】](https://amezou.com/posts/2020/03/22/cli-lambda/)でGet Metric Dataを実行した際には次のようなレスポンスが返ってきてました。

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

Lambdaのレスポンスを見るとほぼ一緒ですね。

```js
{
  ResponseMetadata: { RequestId: '54b80e1c-2a05-4128-b47f-819fc5d5daa6' },
  MetricDataResults: [
    {
      Id: 'monitoringAwsCostPerDay',
      Label: 'EstimatedCharges',
      Timestamps: [Array],
      Values: [Array],
      StatusCode: 'Complete',
      Messages: []
    }
  ],
  Messages: []
}
```

Slackのフォーマットは「[Message Formatting](https://api.slack.com/docs/messages/builder)」で確認できます。難しい表記は要らないので純粋に下記のようなフォーマットにします。

```
{
    "text": "XXX日の請求金額",
    "attachments": [
        {
            "text": "0.12$"
        }
    ]
}
```

## 4. Slackに通知

Slack送信部分は[@slack/webhook](https://www.npmjs.com/package/@slack/webhook)を利用。

```js
await webhook.send({
    text    : `${formatted_today}時点の金額は下記の通りです。`,
    channel : "#aws-notifications",
    attachments: [{"text": `Total Cost: ${usd_cost}$`}]
});
```

Webhook URLの取得は「[slackのIncoming webhookが新しくなっていたのでまとめてみた](https://qiita.com/kshibata101/items/0e13c420080a993c5d16)」が詳しいです。


## 実際に試してみる
きちんと届いてますね！
{{<figure src="/images/2020/03-22-cost-lambda-03.png">}}

あとはこれを定期実行させれば良いですね。
