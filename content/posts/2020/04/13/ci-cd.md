---
title : "[CI/CD] Github ActionsとS3を連携させる[developmentブランチ編]"
date  : 2020-04-13T09:21:59Z
draft : false
tags  : [
    "aws",
    "s3",
    "github",
]
categories: [
    "AWS",
    "CI/CD",
    "DevOps"
]
meta_image  : "/thumbnails/2020-04-13-ci-cd.png"
description : ""
---

今回は[[CI/CD] Github ActionsとS3を連携させる[プラン編]](https://amezou.com/posts/2020/04/05/github-actions/)の続きです。

# やりたいことの確認

前回記事よりやりたいことを再度確認します。

> 1. 差分があるものを更新する
> 2. githubに存在しない古いファイルは消す
> 3. 記事生成・アップロードを自動化させる

今回は下記のようなgit flowを用いてCI/CD化していきます。

{{<figure src="/images/2020/04-13-ci-cd-01.png">}}

1. (手動)ユーザは作成した記事(Markdownファイル)をdevelopmentブランチで管理する。
2. (自動)自動生成されるpublicフォルダ及びTwitterカード画像は変更差分が自動でdevelopmentブランチ上にgit pushされ、管理される。
3. (手動)ユーザがdevelopmentの記事を確認後、手動でmasterブランチへマージする。
4. (自動)マージされたファイルなどは全てブログへアップロードされる。

どの製品もそうですが何もテストせずにいきなり本番環境へアップロードするのだけはあり得ません。少なからずテスト環境で自動及び手動のテストを行った上で本番へデプロイします。

テストの代わりにmergeする際に目視確認する手順を踏むようにしています。こうすることでどんな変更があるかを把握した上でデプロイすることが可能です。

## どんな選択肢があるのか

ブログへデプロイする方法は次の通りが考えられます。

- gitコマンドを使って変更分だけをincludeして更新
- AWS S3コマンドのsize onlyオプションを利用

### gitコマンドを使って変更分だけをincludeして更新

記事は下記が参考になります

 - [AWS S3 sync - only modified files, using git status](https://www.lambrospetrou.com/articles/aws-s3-sync-git-status/)

やってることは全ての変更を除外し、 gitコマンドで差分があるものだけをincludeするだけ。これの欠点としては、publicフォルダもgithub上で管理しないといけないこと。

この方法 + publicフォルダを自動生成するやり方がが恐らくベストプラクティスのような気がします。ただ、実装にも時間が掛かるので別の機会に取り扱うことにします。

### AWS S3コマンドのsize onlyオプションを利用
`aws s3 sync help`コマンドを叩くとどんなオプションがあるのかを調べることができます。

そしてこのコマンドでは次の2つでしかファイルの変更を知り得ません。

- 最終更新時間
- ファイルサイズ

Hugoの記事作成をすると毎回既存の記事もファイルの更新日が変更されるため、最終更新時間での変更は古い変更のない記事までもアップロードすることになってしまいます。

なので今回はファイルサイズの変更がある場合のみ、S3にアップロードする仕組みとします。

ここで1つ注意点があり、ファイルサイズが全く変わらない変更は反映されません。ただ実際にそういった場面はかなり少ないと思われるので無視します。

# すること手順

developmentブランチ上では次の２点を行います。

1. Hugo及び画像生成コマンドを実行
2. 成果物をgithub上にアップロード

ひとまずdevelopmentブランチ上でテストをしながら作成していきます。

## 1. Hugo及び画像生成コマンドを実行

- main.yml
```yaml
name: development

on:
  push:
    branches: [ development ]

jobs:
  deploy:
    name: Create Hugo contents & Push to development branch
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python: [3.6]
        
    steps:
    # Githubレポジトリのファイルにアクセスする用
    - name: Checkout
      uses: actions/checkout@v2
      with:
          submodules: true  # Fetch Hugo themes
    # Hugoのインストール
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.68.3'
    # Make deploy用に先にpublicフォルダを生成
    - name: Deploy hugo
      run: hugo
    - name: Setup Python
      uses: actions/setup-python@v1
      with:
        python-version: ${{ matrix.python }}
    # 自動画像生成に必要なライブラリ郡
    - name: Install pillow via pip
      run: pip install Pillow==7.0.0
    - name: Install pyyaml via pip
      run: pip install pyyaml==5.3.1
    # Makefileのdeployを実行
    - name: Make deploy
      run: make deploy
```

実際にデプロイされてますね。

{{<figure src="/images/2020/04-13-ci-cd-02.png">}}

### 参考にしたサイト

- [Github - peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo)
- [GitHub ActionsでのPythonの利用](https://help.github.com/ja/actions/language-and-framework-guides/using-python-with-github-actions)

- [Push to origin from GitHub action](https://stackoverflow.com/questions/57921401/push-to-origin-from-github-action/58393457#58393457)

## 2. 成果物をgithub上にアップロード

## 3. AWS S3コマンドでウェブサイトと同期

