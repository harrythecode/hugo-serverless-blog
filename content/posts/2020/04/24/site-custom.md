---
title : "「hugo/notepadium」にfaviconとロゴの追加、CSSの改良"
date  : 2020-04-24T14:42:53Z
draft : false
tags  : [
    "hugo",
    "hugo-custom",
]
categories: [
    "サーバレスブログ"
]
meta_image  : "/thumbnails/2020-04-24-site-custom.png"
description : ""
---

今回は、faviconとロゴの追加、そして少しだけCSSを改良します。

# 変更点

- faviconの作成
- ロゴの追加
- CSSの微改良

## faviconの作成

[様々なファビコンを一括生成。favicon generator](https://ao-system.net/favicongenerator/)にてfaviconを作成。ロゴ自体は[Canva](https://www.canva.com/ja_jp/create/logos/)を利用して作成しています。

{{<figure src="/favicon.ico" title="作成したfavicon.ico">}}

- 「static/favicon.ico」を追加。

```
hugo-serverless-blog$ tree -d -L 1
├── archetypes
...
├── static
│   ├── custom-css
│   └── favicon.ico
└── themes
```

- `themes/hugo-notepadium-custom/layouts/partials/head.html`
  * favicon用のlinkタグを追記。
```html
<meta name="supported-color-schemes" content="light dark">
<link rel="icon" type="image/vnd.microsoft.icon" href="/favicon.ico">
```

## ロゴの追加

- config.tomlのparams配下にlogoを追加。

```yaml
[params]
logo    = "/images/sites/2020-04-24-icon-72x72.png"
```

- 「static/images/sites」にロゴ画像を配置。

{{<figure src="/images/2020/04-24-site-custom-03.png" title="1番上にこのように表示されます">}}

## CSSの微改良


- 「themes/hugo-notepadium-custom/assets/css/font.css」で「section.footnotes p」のpaddingを0に設定。
```css
.article-container p { font-size: 18px; line-height: 2 ; padding:16px 0; margin: 0;}
.article-container section.footnotes p { padding: 0;}
```

次のように変化します。

> Before: {{<figure src="/images/2020/04-24-site-custom-01.png">}}
> After: {{<figure src="/images/2020/04-24-site-custom-02.png">}}
