---
title : "[CI/CD] Github ActionsとS3を連携させる[Git + AWS S3 Sync編]"
date  : 2020-04-26T07:42:20Z
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
meta_image  : "/thumbnails/2020-04-26-git-actions.png"
description : ""
---

以前、[[CI/CD] Github ActionsとS3を連携させる[AWS S3 Sync編]](https://amezou.com/posts/2020/04/17/aws-s3-sync/)において「`--size-only`」オプションを利用して更新していましたが、1つ気になることを発見、それは「CSS」を変更する度に新しいcss.minファイルが生成されることです。

{{<figure src="/images/2020/04-26-git-actions-01.png">}}

毎回上図のように各HTMLファイルのCSSが変更されるのですが、integrity値が仮に前回と同じ文字数だった場合、CSSが変更されない、と言う問題が発生します。

どの程度の確率で起こり得るのかは分かりませんが放置するのは良くないと判断したので「aws s3 sync」コマンドに少し修正を加えます。

# 変更点
「`git`」コマンドで「public」フォルダ配下で変更があるもの全てを対象として「`aws s3 sync`」コマンドを実行します。

- aws_s3_sync_with_git_status.sh [^1]
  - S3 Bucketの部分を引数で指定できるように変更しました。
```sh
#!/bin/bash

# https://dev.classmethod.jp/articles/git-avoid-illegal-charactor-tips/
# To be able to show Japanese characters in git command
git config --local core.quotepath false

while getopts b: option
do
case "${option}"
in
    b) S3_BUCKET=${OPTARG};;
esac
done

echo "Target: ${S3_BUCKET}"

if [ -z ${S3_BUCKET} ]
then
    echo "How to use: -b <S3 Bucket Name>"
    exit 1
fi

FILES=()
for i in $( git diff-tree --no-commit-id --name-only -r HEAD | sed 's/"//g' | grep 'public/' | sed 's/^public\///g'); do
    FILES+=( "$i" )
done
# echo "${FILES[@]}"

CMDS=()
for i in "${FILES[@]}"; do
    CMDS+=("--include=$i")
done
# echo ${CMDS[@]}

echo "${CMDS[@]}" | xargs aws s3 sync ./public s3://${S3_BUCKET}/public --delete --exclude "*"
```

> 「`git diff-tree`」コマンドを用いて直前のcommitに含まれる変更ファイルのみを対象としています。
> 「`git config --local core.quotepath false`」にて日本語の文字化けを解消しています。

- [.github/workflows/s3_sync_on_master.yml](https://github.com/amezousan/hugo-serverless-blog/blob/master/.github/workflows/s3_sync_on_master.yml)
  - 先程作成したshellスクリプトを実行するように変更。念のためファイルの実行権限も付与します。

```yaml
- name: Sync files to S3 with the AWS CLI
  run: |
    chmod +x ./aws_s3_sync_with_git_status.sh
    ./aws_s3_sync_with_git_status.sh -b ${{ secrets.AWS_S3_BUCKET }}
```

以上で変更は終了です。

[^1]: [AWS S3 sync - only modified files, using git status](https://www.lambrospetrou.com/articles/aws-s3-sync-git-status/)
