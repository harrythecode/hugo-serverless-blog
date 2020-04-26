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

以前、[[CI/CD] Github ActionsとS3を連携させる[AWS S3 Sync編]](https://amezou.com/posts/2020/04/17/aws-s3-sync/)において「--size-only」オプションを利用して更新していましたが、1つ大きな問題を発見しました。

hugoデプロイを実行する度に新しいcssファイルが作成されるのですが、そのファイルがpublicフォルダ上に

# 変更点
「`git status`」コマンドで「public」フォルダ配下で変更があるもの全てを対象として「`aws s3 sync`」コマンドを実行します。
