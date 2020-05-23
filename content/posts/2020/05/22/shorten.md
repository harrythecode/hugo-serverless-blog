---
title : "最近あちこちに情報発信をしているので省略URLを作ってみた"
date  : 2020-05-22T21:02:13Z
draft : false
tags  : [
    "html",
    "javascript",
]
categories: [
    "小ネタ"
]
meta_image  : "/thumbnails/2020-05-22-shorten.png"
description : ""
---

タイトルの通りです。「Twitter, Note」をメインに情報発信していましたが、本日Youtubeにてスウェーデン語の情報も発信するようになりました。

# 対象URLを決める
取り敢えず僕がユーザとして見たいページのリンクをリストアップしてみます。

1. noteプロフィール [https://note.com/amezousan/n/na786e0b2840a](https://note.com/amezousan/n/na786e0b2840a)
    * 👉「[amezou.com/note](https://amezou.com/note)」に短縮したい
2. youtubeチャンネル [https://www.youtube.com/channel/UCHPpT0Dtun0jTamZG6Wpeew/](https://www.youtube.com/channel/UCHPpT0Dtun0jTamZG6Wpeew/)
    * 👉「[amezou.com/tube](https://amezou.com/tube)」に短縮したい

そんなにありませんね！意外と悲しい！

# どうやって短縮URLを作るか

技術的には大まかに下記3つがあります。

* 動的アプリを作成し、HTTPステータス(301,302)をきちんと設定して飛ばす
* HTMLのRefreshタグを使う
* JavaScriptのLocationを使う

今回は手間をかけたくないので「HTMLのRefresh」で解決しようと思います。

# 変更点

今回は次の記事を参考にしました👉[質問箱のurlが長いので、短縮urlを自作してみた](https://encr.jp/blog/posts/20200304_morning/)

HTMLの文法を修正して以下のようになりました！

* 変更箇所
```sh
hugo-serverless-blog$ tree -L 3
.
├── Makefile
├── README.md
...
├── static
│   ├── note
│   │   └── index.html #「note」フォルダにindex.htmlを追加
│   ├── tube
│   │   └── index.html #「tube」フォルダにindex.htmlを追加
```

* static/note/index.html
```html
<html>
<head>
<meta http-equiv="refresh" content="0;URL=https://note.com/amezousan/n/na786e0b2840a">
<title>転送URL</title>
</head>
<body>
自動で転送されない場合には<a href="https://note.com/amezousan/n/na786e0b2840a">こちら</a>をクリックしてください。
</body>
</html>
```

* static/tube/index.html
```html
<html>
<head>
<meta http-equiv="refresh" content="0;URL=https://www.youtube.com/channel/UCHPpT0Dtun0jTamZG6Wpeew/">
<title>転送URL</title>
</head>
<body>
自動で転送されない場合には<a href="https://www.youtube.com/channel/UCHPpT0Dtun0jTamZG6Wpeew/">こちら</a>をクリックしてください。
</body>
</html>
```

これで完成！

* noteプロフィール　[amezou.com/note](https://amezou.com/note)
* youtubeチャンネル [amezou.com/tube](https://amezou.com/tube)

# (追記:20200523 10:12 UTC+2) 小さなバグ発見

このブログをアップロードした時点で以下2つのバグを発見しました。

* リダイレクト先のページが文字化けしてる
* 「/」なしのURLにアクセスすると「/public」が勝手につく

順に解説していきます。

## リダイレクト先のページが文字化けしてる

下記が実際の画像です。見事に文字化けしてますね！これの原因はページを編集時には「UTF-8」で書いてたのに実際のページでは「Unicode」と言う別の文字エンコードが指定されたことにより発生しています。

{{<figure src="/images/2020/05-22-shorten-01.png">}}

これの解決策は、該当ページにで文字エンコードを指定すれば良いです。

```diff
diff --git a/static/note/index.html b/static/note/index.html
index 33bccb0..3725e72 100644
--- a/static/note/index.html
+++ b/static/note/index.html
@@ -1,5 +1,6 @@
 <html>
 <head>
+<meta charset="UTF-8">
 <meta http-equiv="refresh" content="0;URL=https://note.com/amezousan/n/na786e0b2840a">
 <title>転送URL</title>
 </head>
diff --git a/static/tube/index.html b/static/tube/index.html
index 8dd740e..4d6c0e4 100644
--- a/static/tube/index.html
+++ b/static/tube/index.html
@@ -1,5 +1,6 @@
 <html>
 <head>
+<meta charset="UTF-8">
 <meta http-equiv="refresh" content="0;URL=https://www.youtube.com/channel/UCHPpT0Dtun0jTamZG6Wpeew/">
 <title>転送URL</title>
 </head>
```

## 「/」なしのURLにアクセスすると「/public」が勝手につく
これは例えば、[amezou.com/note](https://amezou.com/note)にアクセスすると「[amezou.com/public/note/](https://amezou.com/public/note/)」にリダイレクトされます。

理由はS3のデフォルトルートへのリダイレクト機能を有効にしているから。本ブログの記事はアクセス制御もかねて公開部分はS3の「/public」フォルダ上に配置されています。

何でこの機能を有効にしたのか忘れましたが確かこれをONにしないとまずかったのを覚えています。

なのでひとまずはpublicフォルダ配下に同じフォルダ・ファイルを作成します。

```sh
$ tree -d
.
├── static
│   ├── custom-css
│   ├── fonts
│   ├── images
│   │   ├── 2020
│   │   └── sites
│   ├── note
│   ├── public
│   │   ├── note # 作成したものをindex.htmlごとコピー
│   │   └── tube # 作成したものをindex.htmlごとコピー
│   ├── thumbnails
│   ├── tube
```

近々S3から別の媒体へと移住する予定なのでそれまでは暫定的な対処で我慢します。