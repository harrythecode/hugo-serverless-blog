---
title : "[CI/CD] Github ActionsとS3を変更点のみ同期させる"
date  : 2020-04-28T07:42:20Z
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
meta_image  : "/thumbnails/2020-04-28-git-actions.png"
description : ""
---

以前、[[CI/CD] Github ActionsとS3を連携させる[AWS S3 Sync編]](https://amezou.com/posts/2020/04/17/aws-s3-sync/)において「`--size-only`」オプションを利用して更新していましたが、1つ気になることを発見、それは「CSS」を変更する度に新しいcss.minファイルが生成されることです。

{{<figure src="/images/2020/04-28-git-actions-01.png">}}

毎回上図のように各HTMLファイルのCSSが変更されるのですが、integrity値が仮に前回と同じ文字数だった場合、CSSが変更されない、と言う問題が発生します。

どの程度の確率で起こり得るのかは分かりませんが放置するのは良くないと判断したので「aws s3 sync」コマンドに少し修正を加えます。

# 成果物

色々と悩んだ結果、以下のような方式に決定しました。

{{<figure src="/images/2020/04-28-git-actions-02.png">}}

1. Releaseブランチ上でPull Requestを作成した際に「public」フォルダを丸ごとコピーして「prev_public」フォルダを作成。(publicフォルダは変更前の状態)
2. Pull Request上で好きなように変更する。この際、publicフォルダは最新の状態に変更される。
3. 「public」と「prev_public」の変更点をチェックし、変更があった部分だけをS3とgithub上の「public」フォルダを同期。

## 変更点
- [hugo_deploy_on_release.yml](https://github.com/amezousan/hugo-serverless-blog/blob/master/.github/workflows/hugo_deploy_on_release.yml)
  - 「pull_request」が「opened」の状態に、rsyncコマンドを使いフォルダを作成。既にファイルが存在する場合は、変更点を全て反映させる。
```yaml
###
# Initial Setup
- name: Sync current Public folder with Previous Public
  if: ( github.event_name == 'pull_request' && github.event.action == 'opened' )
  run: rsync --itemize-changes --checksum --delete --recursive public/ prev_public/
# //
###
```

- [aws_s3_sync_with_git_status.sh](https://github.com/amezousan/hugo-serverless-blog/blob/master/aws_s3_sync_with_git_status.sh)
  - 先程のrsyncコマンドを再度利用。
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
    echo "How to use: -b <S3 Bucket Name>"
    exit 1
fi

FILES=()
for i in $( rsync --itemize-changes --checksum --dry-run --delete --recursive public/ prev_public/|awk '{print $2}' ); do
    FILES+=( "$i" )
done
echo "${FILES[@]}"

CMDS=()
for i in "${FILES[@]}"; do
    CMDS+=("--include=$i")
done
echo ${CMDS[@]}

echo "${CMDS[@]}" | xargs aws s3 sync ./public s3://${S3_BUCKET}/public --delete --exclude "*"
```

- [s3_sync_on_master.yml](https://github.com/amezousan/hugo-serverless-blog/blob/master/.github/workflows/s3_sync_on_master.yml)
  - 先程作成したshellスクリプトを実行するように変更。念のためファイルの実行権限も付与します。

```yaml
- name: Sync files to S3 with the AWS CLI
  run: |
    chmod +x ./aws_s3_sync_with_git_status.sh
    ./aws_s3_sync_with_git_status.sh -b ${{ secrets.AWS_S3_BUCKET }}
```

以上で変更は終了です。
