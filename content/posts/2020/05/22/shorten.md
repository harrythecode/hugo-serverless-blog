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