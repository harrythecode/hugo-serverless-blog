---
title : "HugoでTwitterカードを表示させる方法"
date  : 2020-03-10T18:08:02+01:00
draft : false
tags  : [
    "hugo",
    "hugo-customize"
]
categories: [
    "サーバレスブログ",
]
meta_image  : "/thumbnails/2020-03-10-twitter-card.png"
description : ""
---

今回はHugoでTwitterカードを表示させる方法について書きます。

別のテーマでも同じ原理でカスタマイズ可能なのでぜひ試してみて下さい。

本記事では「[hugo-notepadium](https://themes.gohugo.io/hugo-notepadium/)」のテーマを元に解説していきます。

# テーマをカスタマイズ

- layouts/partials/head-extra.html
```yaml
{{- partial "sns-card.html" . -}}
```

- layouts/partials/sns-card.html
```html
<!-- Enable SNS card-->
<meta property="og:site_name"           content="{{ .Site.Title }}">
<meta property="og:title"               content="{{ .Title }}">
<meta property="og:url"                 content="{{ .Permalink | absURL }}">
<meta property="og:type"                content="{{ if .IsPage }}article{{ else }}website{{ end }}">
<meta name="twitter:card"               content="summary_large_image">
<meta property="twitter:title"          content="{{ .Title }}">
{{ if .Params.description }}
    {{ with .Params.description }}
    <meta property="og:description"         content="{{ . }}">
    <meta property="twitter:description"    content="{{ . }}">
    {{ end }}
{{ else }}
    <meta property="og:description"         content="{{ .Site.Params.slogan }}">
    <meta property="twitter:description"    content="{{ .Site.Params.slogan }}">
{{ end }}
{{ if .Params.meta_image }}
    {{ with .Params.meta_image }}
    <meta property="og:image"       content="{{ . | absURL }}">
    <meta property="og:image:url"   content="{{ . | absURL }}">
    {{ end }}
{{ else }}
    <meta property="og:image"       content="{{ .Site.Params.og_image | absURL }}">
    <meta property="og:image:url"   content="{{ .Site.Params.og_image | absURL }}">
{{ end }}
```

## Twitterカードの解説

Twitterカードとは何か？下記の記事がわかりやすくてオススメです。

[【2020年版】Twitterカードとは？使い方と設定方法まとめ](https://saruwakakun.com/html-css/reference/twitter-card)

- "og"タグはTwitterやFacebookなど幅広いSNSで使用されるタグです。"twitter"タグはTwitterのみで使用されます。
- `{{ "相対パス" | absURL }}`を使うと「https://amezou.com/相対パス」のようなURLを自動で作ってくれます。(参考: [hugo functions-absURL](https://gohugo.io/functions/absurl/))
- `{{ with .Params.meta_image }}`で各記事内の「meta_image」の値を「.Params.meta_image」と繰り返さずに何度も使えます。
- 「.Site.Params」は後述する「`config.toml`」ファイルの値を参照します。


# 記事の作成

## デフォルト設定
- config.toml
```toml
[params]
og_image = "/thumbnails/default.png"
```
「og_image」は各記事内でTwitterカードの画像情報がない場合にデフォルトで表示される画像です。

## デフォルトカード画像
デフォルトの画像はこんな感じ。

{{< figure src="/images/2020/03-10-twitter-card-01.png" width="400" title="Twitterカードの例" >}}

## 記事内で指定

- [how-to-enable-twitter-card-in-a-hugo-theme.md](https://amezousan.com/posts/2020/03/10/how-to-enable-twitter-card-in-a-hugo-theme/)
```yaml
title : "クラウドエンジニアはTerraformを使うべし"
date  : 2020-03-08T01:53:31+01:00
description: "説明"
draft : false
tags  : [
    "blog",
    "terraform",
    "serverless",
]
categories: [
    "雑記",
    "エンジニア思考"
]
meta_image: "/thumbnails/2020-03-08-cloud-engineer-must-use-terraform.png"
```

画像を指定するのこのような感じに。

{{< figure src="/images/2020/03-10-twitter-card-02.png" width="400" title="Twitterカードの例" >}}

# コンテンツの配置
コンテンツは「`static/thumbnails/`」フォルダに入れます。

```
static
└── thumbnails
    ├── 2020-03-08-cloud-engineer-must-use-terraform.png
    ├── 2020-03-10-how-to-enable-twitter-card-in-a-hugo-theme.png
    └── default.png
```

# 最後に
Hugoのカスタマイズは少し癖がありますが、基本的にはHTMLベースなので理解しやすいですね。

使えば使うほど、自分のオリジナリティが出る良いフレームワークだと思います。これからもどんどんカスタマイズしていきます。
