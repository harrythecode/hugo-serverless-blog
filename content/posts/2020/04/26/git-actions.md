---
title : "[CI/CD] Github ActionsとS3を連携させる[Git Status + AWS S3 Sync編]"
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
「`git status`」コマンドで「public」フォルダ配下で変更があるもの全てを対象として「`aws s3 sync`」コマンドを実行します。

- aws_s3_sync_with_git_status.sh [^1]
  - S3 Bucketの部分を引数で指定できるように変更しました。
```sh
#!/bin/bash

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
    echo "How to use: -s3 <S3 Bucket Name>"
    exit 1
fi

FILES=()
for i in $( git status -s | sed 's/\s*[a-zA-Z"?]\+ \(.*\)/\1/' | sed 's/"//g' | grep "public/"); do
    FILES+=( "$i" )
done
# echo "${FILES[@]}"

CMDS=()
for i in "${FILES[@]}"; do
    CMDS+=("--include=$i""*")
done
# echo ${CMDS[@]}

echo "${CMDS[@]}" | xargs aws s3 sync ./public s3://${S3_BUCKET}/public --delete --exclude "*"
```

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
