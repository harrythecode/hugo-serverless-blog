---
title : "[CI/CD] Github ActionsとS3を連携させる[AWS S3 Sync編]"
date  : 2020-04-17T04:05:37Z
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
meta_image  : "/thumbnails/2020-04-17-aws-s3-sync.png"
description : ""
---

今回はいよいよCI/CDの Continuous Delivery (継続デリバリ) を完成させます。

下記の手順は既に終えているものとします。

- [[CI/CD] Github ActionsとS3を連携させる[releaseブランチ編]](https://amezou.com/posts/2020/04/13/ci-cd/)
- [[CI/CD] Github ActionsとS3を連携させる[プラン編]](https://amezou.com/posts/2020/04/05/github-actions/)

# 今回のやることをおさらい

下記がやりたいことの概要です。

> 1. 差分があるものを更新する
> 2. githubに存在しない古いファイルは消す
> 3. 記事生成・アップロードを自動化させる

下記の図は実際に記事を作成する際の手順です。

{{<figure src="/images/2020/04-13-ci-cd-01.png">}}

1. (手動)masterよりブランチを切って「release/yyyymmdd」ブランチ上で記事作成を行う。
2. (手動&自動)Pull Requestを作成・変更する度にHugoDeploy(サムネイル画像生成)が自動で実行され、変更分はreleaseブランチ上にコミットされる。
3. (自動)Pull Request上の変更を確認後、手動でmasterブランチへマージする。
4. (自動)マージされたファイルなどは全てブログへアップロードされる。

前回までで1-3を完成させたので、**今回は手順4を完成させます。**

## どんな選択肢があるのか

AWS S3とGithubの連携には、AWS S3 Sync[^1]コマンドを利用します。そのコマンドを利用して考えられる手法として以下があります。

- gitコマンドで変更分のみをアップロード
- size-onlyオプションを利用

### gitコマンドで変更分のみをアップロード

「s3 sync only modified」と調べる[^2]と、gitコマンドを利用して変更があるものだけを「include」それ以外全てを「exclude」するオプションで変更する方法が紹介されていました。

ウェブサイトで利用されるものは全て「public」フォルダに保存されるので、それを指定すれば良さそうですね。

ただ今回は非常に単純な方針を取りたいと考えているので別の手順を採用します。

### size-onlyオプションを利用

AWS CLIのリファレンスを良く読むと、S3 Syncコマンドは、下記の違いを元にファイルを同期することが可能です。

- ファイルの最終更新日
- ファイルサイズ

Hugoの記事を生成する度に既存の記事も更新されるので「最終更新日」を利用することのは無駄です。

記事を作成、修正する際に全く同じファイルサイズになることは滅多にあり得ないので今回は「ファイルサイズ」の違いがあれば全てのファイルを同期する方法を採用します。

## 完成品

- [.github/workflows/s3_sync_on_master.yml](https://github.com/amezousan/hugo-serverless-blog/blob/master/.github/workflows/s3_sync_on_master.yml)

```yaml
name: SyncGitrepoWithS3

# Controls when the action will run. Triggers the workflow on push or pull request
# events but only for the master branch
on:
  push:
    branches: [ master ]

jobs:
  deploy:
    name: Sync git repo with AWS S3
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

    - name: Sync files to S3 with the AWS CLI
      run: |
        aws s3 sync ./public s3://${{ secrets.AWS_S3_BUCKET }}/public --size-only --delete
```

S3のコマンドを実行するために「[aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)」を採用しています。後はプラン編で入力したSecretsを用いて設定するだけ。

下記の手順を用いて構築した際に「terraform-init-role」ロールがS3のフルアクセスを持っているのでそちらを再利用します。

[【保存版】爆速！サーバレスブログの作り方【Hugo + AWS(S3,Route53,Cloudfront)】](https://amezou.com/posts/2020/03/07/serverless-blog/)

## 記事作成手順

[前回記事](https://amezou.com/posts/2020/04/13/ci-cd/)を実際に公開するまでの手順書を紹介します。

### 手順1:「release/yyyymmdd」ブランチ上で記事作成

1. masterブランチからgit pull
```sh
[master]$ git pull
```

2. release/yyyymmddブランチを作成
```sh
$ git checkout -b "release/20200416"
Switched to a new branch 'release/20200416'
[release/20200416]$ git push
fatal: The current branch release/20200416 has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin release/20200416

[release/20200416]$ git push --set-upstream origin release/20200416
```

> set-upstreamオプションをつけてレポジトリ上に「release/20200413」ブランチを作成します。
> 自分はいつも引数を書くのが面倒なので存在しないブランチをとりあえずpushしています。

3. 記事作成 & 執筆
```sh
$ hugo new posts/2020/04/13/ci-cd.md
```

> [hugo-serverless-blog - Makefile](https://github.com/amezousan/hugo-serverless-blog/blob/master/Makefile)を使える方は、`$ make create TITLE='ci cd'`のコマンドを実行するだけで上記コマンドと同じことができます。

### 手順2: Pull Requestを作成・変更

1. 好きなようにコードをcommitする

{{<figure src="/images/2020/04-17-aws-s3-sync-01.png">}}

> 新しくPRを作成する、あるいはタイトル名を変更すると作成したmdファイルに合わせて記事とサムネイルが自動生成されます。

2. 複数のコミットを1つのコミットに変換する「git squash」を行います。
    - 「release/20200416」ブランチ
{{<figure src="/images/2020/04-17-aws-s3-sync-02.png">}}
    - 「master」ブランチ
{{<figure src="/images/2020/04-17-aws-s3-sync-03.png">}}

3. (以降の手順は省略可能です。後でブラウザ上でも出来ます。) git rebaseコマンドを利用してsquashします。

```sh
# commit id「a818eac」の次の「7e65f80」までを対象とします。
[release/20200416]$ rebase -i 7e65f80eeda50ccacf3e5865c1ebb63c529b0dd2^

# 最後のcommit以外を全て「squash」します。
1 pick 7e65f80 Update workflows
2 s 708ac78 Remove tab in workflow
3 s 524bb3c Blog 20200413-16
4 s d79bfcf Automated deployment
5 s e078265 Automated deployment
6
7 # Rebase a818eac..e078265 onto d79bfcf (5 commands)
8 #
9 # Commands:
10 # p, pick <commit> = use commit
11 # r, reword <commit> = use commit, but edit the commit message
12 # e, edit <commit> = use commit, but stop for amending
13 # s, squash <commit> = use commit, but meld into previous commit

# エディタ上で上書きして終了すると次にコメントをどうするかを聞かれます。
# 既存コメントを全てコメントアウト(#)して「Release 20200416」と書きます。
 1 # This is a combination of 5 commits.
 2 # This is the 1st commit message:
 3
 4 # Update workflows
 5
 6 # This is the commit message #2:
 7
 8 # Remove tab in workflow
 9
10 # This is the commit message #3:
11
12 # Blog 20200413-16
13
14 # This is the commit message #4:
15
16 # Automated deployment
17
18 # This is the commit message #5:
19
20 Release 20200416
```

4. エディタを終了して現在の状況を確認します。
```sh
[release/20200416]$ git log
commit 3896c54f4224caec9e04295e7fca855a5c7aa8fb (HEAD -> release/20200416)
Author: amezousan <...>
Date:   Thu Apr 16 17:23:28 2020 +0000

    Release 20200416

commit a818eacff25d24c06b9ce50f6c6f9bd5f66ba04b (origin/master, origin/HEAD, master)
Author: amezousan <...>
Date:   Mon Apr 13 17:03:09 2020 +0200
```

5. 意図した通りにcommitが書き換わったら現在のreleaseブランチを強制的に上書きします。
```sh
[release/20200416]$ git push origin release/20200416 --force
Enumerating objects: 100, done.
Counting objects: 100% (100/100), done.
Compressing objects: 100% (45/45), done.
Writing objects: 100% (53/53), 343.21 KiB | 6.48 MiB/s, done.
Total 53 (delta 24), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (24/24), completed with 22 local objects.
To https://github.com/amezousan/hugo-serverless-blog.git
 + e078265...3896c54 release/20200416 -> release/20200416 (forced update)
```

> 「git push -f, --force」を何気なく使うと非常に危険です。必ず自分がどのブランチに対して上書きしようとしているかを確認した上で実行してください。
> 過去のコード、履歴を全て消し去るので間違ってもmasterブランチへ実行するのは辞めましょう。

### 手順3: Pull Request上の変更を確認後、手動でmasterブランチへマージ
1. Pull Requestに戻り変更内容を確認します。
{{<figure src="/images/2020/04-17-aws-s3-sync-04.png">}}

2. 内容に満足したらマージします。
{{<figure src="/images/2020/04-17-aws-s3-sync-05.png">}}

> マージする際にsquashオプションが選べます。こちらの方法でも先程のコマンド実行と同じことができます。

### 手順4: マージされたファイルなどは全てブログへアップロードされる。
1. Github Actionsを見ると実際にアップロードされているのが確認できます。
{{<figure src="/images/2020/04-17-aws-s3-sync-06.png">}}

今回は以上です。

[^1]: [AWS Cli Reference - s3](https://docs.aws.amazon.com/cli/latest/reference/s3/)
[^2]: [AWS S3 sync - only modified files, using git status](https://www.lambrospetrou.com/articles/aws-s3-sync-git-status/)
