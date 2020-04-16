---
title : "[CI/CD] Github ActionsとS3を連携させる[releaseブランチ編]"
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

1. (手動)masterよりブランチを切って「`release/yyyymmdd`」ブランチ上で記事作成を行う。
2. (手動&自動)Pull Requestを作成・変更する度にHugoDeploy(サムネイル画像生成)が自動で実行され、変更分はreleaseブランチ上にコミットされる。
3. (自動)Pull Request上の変更を確認後、手動でmasterブランチへマージする。
4. (自動)マージされたファイルなどは全てブログへアップロードされる。

releaseブランチはマージ後に削除する「GitHub Flowモデル[^1]」を採用します。

どの製品もそうですが何もテストせずにいきなり本番環境へアップロードするのだけはあり得ません。少なからずテスト環境で自動及び手動のテストを行った上で本番へデプロイします。

テストの代わりにmergeする際に目視確認する手順を踏むようにしています。こうすることでどんな変更があるかを把握した上でデプロイすることが可能です。

# すること手順

releaseブランチ上では次の２点を行います。

1. Hugo及び画像生成コマンドを実行
2. 成果物をgithub上にアップロード

## 完成品

先に完成品をお見せします。

- hugo_deploy_on_release.yml
```yaml
name: HugoDeployOnPullRequest

on:
  pull_request:
    types: [ opened, edited ]

jobs:
  deploy:
    # "github.head_ref" returns the branch name on the pull request
    if: contains(github.head_ref, 'release') == true
    name: Create Hugo contents & Push to the release branch
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python: [3.6]
        
    steps:

    ###
    # Initial Setup
    - name: Checkout
      uses: actions/checkout@v2
      with:
          ref: ${{ github.head_ref }}
    - name: Setup Hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.68.3'
    # //
    ###

    ###
    # Install Python & Library for Automatic Thumbnail Script
    - name: Setup Python
      uses: actions/setup-python@v1
      with:
        python-version: ${{ matrix.python }}
    - name: Install pillow via pip
      run: pip install Pillow==7.0.0
    - name: Install pyyaml via pip
      run: pip install pyyaml==5.3.1
    - name: Make deploy
      run: make deploy
    # //
    ###

    ###
    # Push to the release branch

    # To be able to push always even if there is no change
    - name: Create report file
      run: date +%s > report.txt

    - name: Commit all changes
      run: |
        ls -la
        git config --global user.email "amezousan@users.noreply.github.com"
        git config --global user.name "amezousan"
        git add --all
        git status
        git commit -m "Automated deployment"
        git push origin ${{ github.head_ref }}
    # //
    ###
```

> Commit all changes内のemailとusernameは適宜各自のユーザ名に修正してください。

Workflowを変更した状態で、Pull Requestを作成します。

{{<figure src="/images/2020/04-13-ci-cd-02.png">}}

するとジョブが実行されていることが分かります。

{{<figure src="/images/2020/04-13-ci-cd-03.png">}}

## ハマったポイント

この記事を作成するに当たってハマったポイントです。

### 開発方法をややこしくしていた

Gitで使われる開発手法の中に「git-flow, GitHub Flow」の2種類があります。

当初git-flow (master - development - release)を想定した作りにしようと考えていましたが、developmentとmasterでコミットの差が生まれるのが非常に煩わしく、もっと単純な方法のGitHub Flow (master - release)に落ち着きました。

### HugoDeployのタイミングが分からなかった

どのタイミングでHugoの記事生成及びサムネイル画像の作成を行えば良いのかが分かりませんでした。「GitHub Actionsのワークフロー構文[^2]」とにらめっこし、試行錯誤の結果「Pull Request」を「作成・編集」する際にHugoDeployを行うことにしました。

この効果は記事作成の際に発揮されます。

### 特定のブランチ名のみを対象とする方法

今後使用されるブランチは「master」(記事反映用)と「release/yyyymmdd」(記事作成用)の2つですが、ブランチ名にreleaseが付く場合のみ、HugoDeployを実行させたいと考えていました。

「github actions branch regex」で調べるとGithubのコミュニティ[^3]で僕と同じ悩みを抱えている人を発見。

そこから発想を得て、ブランチ名に「release」が含まれている場合のみ「deploy」ジョブを実行するif文を追加しました。

```yaml
jobs:
  deploy:
    # "github.head_ref" returns the branch name on the pull request
    if: contains(github.head_ref, 'release') == true
```

> github.head_ref変数[^4]はブランチの状態によって値が変化するので注意。Pull Request上ではブランチ名を返します。

### git commitが面倒だった

HugoDeployで作成したものをreleaseブランチにcommitさせようとしたのですが、actions/checkout[^5]のオプション無しでは上手くいきませんでした。と言うのもreleaseブランチを参照しているだけで、そのブランチにcheckoutした訳ではないからです。

なので下記の通り「release」ブランチにcheckoutするようにオプションを追加しました。

```yaml
    - name: Checkout
      uses: actions/checkout@v2
      with:
          ref: ${{ github.head_ref }}
```

### Hugoのテーマをレポジトリに追加

今までを改造してきたHugoテーマの内容をフォルダを名前変更し「hugo-notepadium-custom[^6]」を作成、masterブランチへアップロードしています。

Github Actionsは僕のローカルで編集した内容を参照できるわけがないのでこうしてレポジトリにコードを上げる必要があります。

# 最後に

もっと楽にできるかと思いましたが想像した以上に厄介な罠があり、完成までに2日ほどかかってしまいました。

次は作成したものをmasterブランチへマージし、その際にaws s3 syncコマンドを使ってウェブサイトと同期させていきます。(実はこの記事がアップロードされてる時点で完成しているのですが…)

## 他に参考にしたサイト
- [Github - peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo)
- [GitHub ActionsでのPythonの利用](https://help.github.com/ja/actions/language-and-framework-guides/using-python-with-github-actions)
- [Push to origin from GitHub action](https://stackoverflow.com/questions/57921401/push-to-origin-from-github-action/58393457#58393457)
- [コミットメールアドレスを設定する](https://help.github.com/ja/github/setting-up-and-managing-your-github-user-account/setting-your-commit-email-address)

[^1]: [【図解】git-flow、GitHub Flowを開発現場で使い始めるためにこれだけは覚えておこう](https://www.atmarkit.co.jp/ait/articles/1708/01/news015.html#02)
[^2]: [GitHub Actionsのワークフロー構文](https://help.github.com/ja/actions/reference/workflow-syntax-for-github-actions)
[^3]: [is there expression syntax to do pattern matching (regex on strings)](https://github.community/t5/GitHub-Actions/is-there-expression-syntax-to-do-pattern-matching-regex-on/td-p/36295)
[^4]: [ワークフローをトリガーするイベント](https://help.github.com/ja/actions/reference/events-that-trigger-workflows)
[^5]: [github actions/checkout](https://github.com/actions/checkout)
[^6]: [hugo-serverless-blog/tree/master/themes/hugo-notepadium-custom](https://github.com/amezousan/hugo-serverless-blog/tree/master/themes/hugo-notepadium-custom)