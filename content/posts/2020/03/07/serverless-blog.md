---
title: "【保存版】爆速！サーバレスブログの作り方【Hugo + AWS(S3,Route53,Cloudfront)】"
date: 2020-03-07T10:17:48+01:00
draft: false
tags: [
    "aws",
    "hugo",
    "serverless",
]
categories: [
    "サーバレスブログ"
]
meta_image: "/thumbnails/2020-03-07-serverless-blog.png"
---

本サイトはサーバレスで構成されています。

{{< figure src="/images/2020/03-07-serverless-blog-01.png" >}}

ブログに使用しているサービスは「Route53, ACM, Cloudfront, S3」です。

ユーザがアクセスする際に使われるドメイン(例えば、amezou.com)をRoute53上で管理して、HTTPSの証明書はACMが管理し、Cloudfrontは、全世界にまたがってS3のコンテンツをキャッシュ(一時的に保存)してくれます。

こうすることで例えば、あなたが日本からアクセスした場合は、日本に近いサーバからこのブログコンテンツが提供され、海外にいた場合は、その国に近いサーバからコンテンツが提供されます。(これが爆速の理由)

サーバレスブログに必要なコンテンツは全てTerraformで管理します。いわゆるコードのインフラ化(IAC; Infra As Code)を行います。コンソールをポチポチいじって設定する必要もなく、コマンド1つで何度も同じリソースを作成・削除・変更が可能です。

🔽詳細は下記ノートから読めます🔽

[【保存版】爆速！サーバレスブログの作り方(1/2)【Hugo+AWS+Terraform】](https://note.com/amezousan/n/n1063cdc9524f)
> (Part1) AWSの環境設定について書きます。


[【保存版】爆速！サーバレスブログの作り方(2/2)【Hugo+AWS+Terraform】](https://note.com/amezousan/n/nc0d5bd3e09e1)
> (Part2) Hugoを使った具体的な記事作成について紹介します。
