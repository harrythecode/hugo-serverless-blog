---
title : "「hugo/notepadium」に「合わせて読む」機能の追加"
date  : 2020-03-18T23:48:00+01:00
draft : false
tags  : [
    "hugo",
    "hugo-custom",
]
categories: [
    "サーバレスブログ"
]
meta_image  : "/thumbnails/2020-03-18-see-also.png"
description : ""
---

今回は本サイトでも使用している「[notepadium](https://themes.gohugo.io/hugo-notepadium/)」テーマに「合わせて読む」機能を追加しようと思います。

本記事は[「hugo/notepadium」にSNSシェアボタンを追加する](https://amezou.com/posts/2020/03/15/sns-share/)の設定を完了したものとして説明を進めます。

# はじめに

今回変更する箇所は下記の通りです。

```
.
└── themes/
    └── hugo-notepadium
        ├── assets
        │   ├── css
        │   │   └── font.css
        └── layouts
            └── partials
                ├── article-labels.html
                └── related.html (新規作成)
```

ネットで探していたら公式の機能で既に用意されていました👉[List Related Content](https://gohugo.io/content-management/related/)

使い方は非常に簡単で公式のサイトからコードをコピー。そして少し変更を加えます。

- layouts/partials/related.html

```html
{{ $related := .Site.RegularPages.Related . | first 3 }}
{{ with $related }}
<section id=related_link>
<h3>合わせて読む</h3><p></p>
<ul>
	{{ range . }}
	<li><a href="{{ .RelPermalink }}">{{ .Title }}</a></li>
	{{ end }}
</ul>
</section>
{{ end }}
<p></p>
<div align=center>...SNSにもシェアしてみる？</div>
```

- layouts/partials/article-labels.html

```html
{{- partial "related.html" . -}}
{{- partial "share.html" . -}}
{{- if or .Params.categories .Params.tags -}}
```

> {{- partial "related.html" . -}}を追加。

- assets/css/font.css

```css
section#related_link ul, section#related_link ol {
  background: #fcfcfc;/*背景色*/
  padding: 0.5em 0.5em 0.5em 2em;/*ボックス内の余白*/
  border: solid 3px gray;/*線の種類 太さ 色*/
}

section#related_link ul li, section#related_link ol li {
  line-height: 1.5; /*文の行高*/
  padding: 0.5em 0; /*前後の文との余白*/
}
```

> [コピペで使えるリストデザイン34選：CSSで箇条書きをおしゃれに](https://saruwakakun.com/html-css/reference/ul-ol-li-design)からコピーしてきましたのをCSSセレクタ「section#related_link」を加えてます。

> CSSセレクタを使用しないと、意図しないリストにも上記のCSSが適用されてしまいます。

# 完成品
結構良いんじゃーないですか。
{{< figure src="/images/2020/03-18-see-also-01.png" title="合わせて読むの例">}}
