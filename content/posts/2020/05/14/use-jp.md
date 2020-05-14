---
title : "Github Actions + AWS CLI (s3 sync)で日本語を使う方法"
date  : 2020-05-14T19:43:32Z
draft : false
tags  : [
    "aws",
    "github",
]
categories: [
    "AWS",
    "CI/CD"
]
meta_image  : "/thumbnails/2020-05-14-use-jp.png"
description : ""
---

今回はタイトル記載している通り「Github Actions + AWS CLI (s3 sync)で日本語を使う方法」を紹介します。

# 何が問題なのか
以前の記事「[[CI/CD] Github ActionsとS3を変更点のみ同期させる](/posts/2020/04/28/git-actions/)」で、AWS CLIのs3 syncコマンドを使ったCI/CDの方法を紹介しました。

実はこの方法、そのまま使うとある問題 - [Fix filename encoding issue #22](https://github.com/amezousan/hugo-serverless-blog/issues/22)がおきます。それが「ファイル名に日本語が含まれるとエラーが起きる」と言う点です。

- [aws_s3_sync_with_git_status.sh](https://github.com/amezousan/hugo-serverless-blog/blob/master/aws_s3_sync_with_git_status.sh)
    * `aws s3 sync ./public s3://${S3_BUCKET}/public --delete --exclude "*" --include="ファイル名" --include="xx"`
```bash
UnicodeDecodeError: 'ascii' codec can't decode byte 0xe3 in position 18: ordinal not in range(128)
2020-05-14 05:30:02,419 - MainThread - awscli.clidriver - DEBUG - Exiting with rc 255

'ascii' codec can't decode byte 0xe3 in position 18: ordinal not in range(128)
xargs: aws: exited with status 255; aborting
##[error]Process completed with exit code 124.
```

AWS S3 Syncコマンドがなぜか日本語文字を受け付けません。

# どのような解決策があるか
* 解決策1. AWS CLIを実行するクライアント上の言語を「UTF-8」で統一。[^1]
    * `$ export LC_ALL=en_US.UTF-8`

手元のMac上では上手くスクリプトが動きますが、Github Actions上では上手くいきませんでした。そして半ば諦めていたのですが、今朝ほどPython2.xと3.x系で日本語の処理動作が異なることに気がつきました。

Python2.x系はPythonコード内で明示的に文字コードを指定しないと日本語が動かないのに対し、Python3.x系は標準の状態で日本語を上手く処理してくれます。

なぜならActions上のUbuntuの最新版(18.04.04(LTS))は「Python2.7」[^2]を使ってAWS CLIを実行しているから。

じゃあGithub ActionsでPython3を使うようにすれば問題解決するんじゃない？と考え試してみたところ上手くいきました。

# 実践例

* `$ git diff .github/workflows/s3_sync_on_master.yml`
    * Python3をインストールして設定します。[^3]
    * 保険のために言語設置をUTF-8に設定しています。
```diff
diff --git a/.github/workflows/s3_sync_on_master.yml b/.github/workflows/s3_sync_on_master.yml
index 19eef82..5747e83 100644
--- a/.github/workflows/s3_sync_on_master.yml
+++ b/.github/workflows/s3_sync_on_master.yml
@@ -10,10 +10,17 @@ jobs:
   deploy:
     name: Sync git repo with AWS S3
     runs-on: ubuntu-latest
+    strategy:
+      matrix:
+        python-version: [3.6]

     steps:
     - name: Checkout
       uses: actions/checkout@v2
+    - name: Set up Python ${{ matrix.python-version }}
+      uses: actions/setup-python@v2
+      with:
+        python-version: ${{ matrix.python-version }}

     - name: Configure AWS credentials
       uses: aws-actions/configure-aws-credentials@v1
@@ -22,8 +29,13 @@ jobs:
         aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
         aws-region: eu-west-1

+    - name: Set up AWS CLI with Python 3.x
+      run: |
+          export LANG=C.UTF-8
+          pip3 install awscli --upgrade
+          aws --version
+
     - name: Sync files to S3 with the AWS CLI
       run: |
         chmod +x ./aws_s3_sync_with_git_status.sh
         ./aws_s3_sync_with_git_status.sh -b ${{ secrets.AWS_S3_BUCKET }}
```

* `$ git diff aws_s3_sync_with_git_status.sh`
    * 保険のためにincludeオプションをダブルクォートで囲います。

```diff
diff --git a/aws_s3_sync_with_git_status.sh b/aws_s3_sync_with_git_status.sh
index 7233885..874ef02 100755
--- a/aws_s3_sync_with_git_status.sh
+++ b/aws_s3_sync_with_git_status.sh
@@ -1,5 +1,7 @@
 #!/bin/bash

+locale
+
 while getopts b: option
 do
 case "${option}"
@@ -24,7 +26,7 @@ echo "${FILES[@]}"

 CMDS=()
 for i in "${FILES[@]}"; do
-    CMDS+=("--include=$i")
+    CMDS+=("--include=\"$i\"")
 done
 echo ${CMDS[@]}
```

これで日本語を含むファイル名が来ても普通に「aws s3 sync」ができるようになります。

[^1]: [https://github.com/aws/aws-cli/issues/1368#issuecomment-232766644](https://github.com/aws/aws-cli/issues/1368#issuecomment-232766644)
[^2]: [https://github.com/actions/virtual-environments/blob/master/images/linux/Ubuntu1804-README.md](https://github.com/actions/virtual-environments/blob/master/images/linux/Ubuntu1804-README.md)
[^3]: [How to use Python3](https://stackoverflow.com/questions/46375082/in-macos-sierra-how-configure-aws-cli-to-use-python3-x-instead-of-the-os-defaul), [Actions - setup python](https://github.com/actions/setup-python)
