---
title : "「hugo/notepadium」にカスタムCSSとfontawesomeの導入"
date  : 2020-03-13T08:47:00+01:00
draft : false
tags  : [
    "hugo",
    "hugo-custom",
]
categories: [
    "サーバレスブログ"
]
meta_image  : "/thumbnails/2020-03-12-custom-css.png"
description : ""
---

今回はhugoのテーマ「[notepadium](https://themes.gohugo.io/hugo-notepadium/)」にカスタムCSSとfontawesomeを導入します。

FontawesomeはCSSだけで次のようなアイコンを使うことができます。非常に使い勝手が良く、色んなアイコンが揃っているのでオススメです。

<i class="fab fa-github fa-3x"></i>
<i class="fab fa-twitter fa-3x"></i>
<i class="fab fa-youtube fa-3x"></i>

- 上記アイコンのHTMLコード
```html
<i class="fab fa-github fa-3x"></i>
<i class="fab fa-twitter fa-3x"></i>
<i class="fab fa-youtube fa-3x"></i>
```

# 今回変更する箇所

```
├── static
│   ├── custom-css (新規作成)
│   └── webfonts   (新規作成)
├── config.toml
└── themes
    └── hugo-notepadium
```

## カスタムCSSの導入
- config.tomlに下記を追加(もちろん名前、パスは自由)

```
[params.assets]
css = ["css/font.css"]
```

フォルダ「themes/hugo-notepadium/assets/」の配下に「css」フォルダを作り「font.css」ファイルを作成します。

- themes/hugo-notepadium/assets/css/font.css

```
.article-container p { font-size: 18px; line-height: 2 ; padding:16px 0; margin: 0;}
h1,h2,h3,h4,h5,h6 {padding-top: 16px;}
```

### 変更前
少し文字の間隔が狭いですよね。

{{< figure src="/images/2020/03-13-custom-css-01.png" >}}

### 変更後
これで少し読みやすくなりました！

{{< figure src="/images/2020/03-13-custom-css-02.png" >}}

## Fontawesomeの導入

### ファイルのダウンロード
[Fontawesome - Download](https://fontawesome.com/download)にアクセスして「Free for Web」ボタンをクリック。

{{< figure src="/images/2020/03-13-custom-css-03.png" >}}

ダウンロードしたzipファイルを解凍すると次のようなフォルダ構成になってます。

```
fontawesome-free-5.12.1-web
├── css
│   ├── all.css
│   └── all.min.css
├── js
├── less
├── metadata
├── scss
├── sprites
├── svgs
│   ├── brands
│   ├── regular
│   └── solid
└── webfonts
```

### ファイルの展開
「css/all.min.css」ファイルをHugoディレクトリ「static」の配下に置きます。この際「custom-css」フォルダを作り「fontawesome-all.min.css」として入れましょう。

```
static/custom-css/
└── fontawesome-all.min.css
```

> all.min.cssとall.cssは同じコンテンツですがファイルサイズが異なります。
> 少しでもファイルの読み込み速度を上げるため「min」版を選んでいます。

「webfonts」フォルダをそのまま「static」フォルダの配下にコピーしましょう。

```
static/
├── custom-css
└── webfonts
```

### テーマのヘッダを変更

「`<link rel="stylesheet" href="{{ "custom-css/fontawesome-all.min.css" | absURL }}">`」をmetaタグの下に追加。

- themes/hugo-notepadium/layouts/partials/head.html

```html
<meta name="supported-color-schemes" content="light dark">
<link rel="stylesheet" href="{{ "custom-css/fontawesome-all.min.css" | absURL }}">
```

後は「`hugo`」コマンドを実行するだけで自動的にコンテンツが生成されます。
