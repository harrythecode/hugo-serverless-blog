---
title : "[CI/CD] Github ActionsとS3を連携させる[実装編]"
date  : 2020-04-11T09:21:59Z
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
meta_image  : "/thumbnails/2020-04-11-ci-cd.png"
description : ""
---

今回は[[CI/CD] Github ActionsとS3を連携させる[プラン編]](https://amezou.com/posts/2020/04/05/github-actions/)の続きです。

前回記事よりやりたいことを再度確認します。



> 1. 差分があるものを更新する
> 2. githubに存在しない古いファイルは消す
> 3. 記事生成・アップロードを自動化させる

