---
title : "[CI/CD] Github ActionsとS3を連携させる[プラン編]"
date  : 2020-04-05T06:51:24Z
draft : false
tags: [
    "aws",
    "s3",
    "github"
]
categories  : [
    "AWS",
    "CI/CD",
    "DevOps",
]
meta_image  : "/thumbnails/2020-04-05-github-actions.png"
description : ""
---

今回は本サーバレスブログをCI/CD化させてみたいと思います。

# はじめに

CI/CDとは「Continuous Integration／Continuous Delivery」の略で、日本語では継続的インティグレーション／継続的デリバリーと言います。

本ブログでは記事を公開する際に下記のような手順を奪っています。

1. 記事作成・執筆
2. Markdownから記事を生成(Makefileを使っているのでmake deployで完成します)
3. publicフォルダのコンテンツをS3にアップロード(Makefile: make uploadでお終い)

上記手順は全て手動で行われています。なのでこの手順を次の通りに変更します。

1. 記事作成・執筆
2. Githubにコミットする
3. (自動)Markdownから記事生成
4. (自動)生成物をS3にアップロード

先程の手順の一部を自動化させます。これをCI/CD化と言います。エンジニアは最新のコードをgithubに上げることだけに集中します。

この手順に更にテストなどを加えた形が実際に世の中で広まっているDevOpsの考え方です。

DevOpsエンジニアとして働くためにはこの手の技術を習得することは必須条件です。

# やりたいこと

今回やりたいことを言語化すると次の通りです。

1. 差分があるものを更新する
2. githubに存在しない古いファイルは消す
3. 記事生成・アップロードを自動化させる

1, 2はCI/CDと言うよりもAWSのコマンドに依存する可能性が高いです。
後で調べるとしてまずは3の自動化方法を考えます。

## どんな選択肢があるのか

パッと思いつく限りだと次の方法が考えられます。

1. Github <-> Github Actions <-> S3
2. Github <-> Circle CI <-> S3
3. Github <-> Jenkins <-> S3

どの方法でも良いのですが、今回は使ったことのないGithub Actionsを選択してみます。

# 連携方法を調べる
"github actions s3"で調べると次のような手法が主流のようです。

- github actionsにCI/CD化する内容のyamlファイルを作成する

更にgithub上で次のようなサンプルを見つけました。-> 
- ["Configure AWS Credentials" Action For GitHub Actions](https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions)

早速試してみたいと思います。設定手順は次を参考にしています。-> [Deploying a React app to AWS S3 with Github Actions](https://medium.com/trackstack/deploying-a-react-app-to-aws-s3-with-github-actions-b1cb9ba75c95)

# Github Actionsを試す
1. CI/CD化するgithubレポジトリにログインした状態で「Settings -> Secrets」へアクセスします。
{{< figure src="/images/2020/04-05-github-action-01.png" >}}

2. "Add a new secret"リンクをクリックし、下記の３つの値を入力します。値は各自の環境に合わせて適宜変更してください。
{{< figure src="/images/2020/04-05-github-action-02.png" >}}

    * AWS_ACCESS_KEY_ID: (AWS S3アップロード用)
    * AWS_SECRET_ACCESS_KEY: (AWS S3アップロード用)
    * AWS_S3_BUCKET: (アップロード対象のS3バケット名)

    > 使用するAccess Key及びSecret Keyのユーザは対象のS3バケットへのアクセス権限が必要です。今回はテスト目的なので一時的に作成したユーザにS3 FullAccessを付与してテストしています。

3. CI/CDするgithubレポジトリのActionsタブをクリックします。
{{< figure src="/images/2020/04-05-github-action-03.png" >}}
4. 今回はテンプレートなしで作成するので「Set up a workflow yourself」を選択
{{< figure src="/images/2020/04-05-github-action-04.png" >}}
3. 次の通り入力し、Workflowのymlファイルを作成します。branch: "helloworld"上で作成することをオススメします。
{{< figure src="/images/2020/04-05-github-action-05.png" >}}
- main.yml
```yaml
name: HelloWorld

# Controls when the action will run. Triggers the workflow on push or pull request
# events but only for the master branch
on:
  push:
    branches: [ helloworld ]

jobs:
  deploy:
    name: Upload to Amazon S3
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v2

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: eu-west-1

    - name: Copy files to S3 with the AWS CLI
      run: |
        aws s3 sync ./helloworld s3://${{ secrets.AWS_S3_BUCKET }}/helloworld
```

> aws-regionは各自の環境に合わせて変更してください。場合によってはsecrets変数にするのもありです。
> branch: "helloworld"を作成することをオススメする理由はgithubの履歴を汚さないためです。テストが終了次第、ブランチを消すだけで後片付けが終了します。

4. helloworldフォルダを作成し、適当なファイルを作成します。
{{< figure src="/images/2020/04-05-github-action-06.png" >}}

5. main.ymlファイルを作成するとデプロイが開始されます。
{{< figure src="/images/2020/04-05-github-action-07.png" >}}

6. S3上に先程作成したファイルがあればテスト完了です。
{{< figure src="/images/2020/04-05-github-action-08.png" >}}

あとはhelloworldブランチを削除すれば後片付け完了です。

> ブランチを削除する前に作成したmain.ymlワークフローを先に削除しましょう。現在のgithub actionsはブランチを削除した際、自動的にワークフローが削除されるような仕組みになっていません。

[Github Forum: Delete old workflow results](https://github.community/t5/GitHub-Actions/Delete-old-workflow-results/td-p/30589)

次回は実際に必要な要件を満たすCI/CD化を目指して行きます。

# 参考にしたサイト
- ["Configure AWS Credentials" Action For GitHub Actions](https://github.com/marketplace/actions/configure-aws-credentials-action-for-github-actions)
- [Deploying a React app to AWS S3 with Github Actions](https://medium.com/trackstack/deploying-a-react-app-to-aws-s3-with-github-actions-b1cb9ba75c95)
- [暗号化されたシークレットの作成と保存](https://help.github.com/ja/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)
