---
title : "「hugo/notepadium」にSNSシェアボタンを追加する"
date  : 2020-03-15T17:50:41+01:00
draft : false
tags  : [
    "hugo",
    "hugo-custom",
]
categories: [
    "サーバレスブログ"
]
meta_image  : "/thumbnails/2020-03-15-sns-share.png"
description : ""
---

今回は本サイトでも使用している「notepadium」テーマにSNSシェアボタンを追加しようと思います。

とりあえずTwitter, Facebookの2つでシェアできるようにしたいと思います。

これ難しそうと思われるかもしれませんが、非常に単純なんです。例えば、リンクを作成する`<a>`タグがありますよね。

```html
<a href=http://example.com>リンク</a>
```

このタグで実際にアクセスする「href」の値をTwitterやFacebookが用意したURLに、あなたがシェアさせたい内容を追加すれば良いだけなんです。

# どんなやり方があるのか
1. 既存のテーマを真似する
2. [AddThis](https://www.trhrkmk.com/posts/hugo-share-button-addthis/)を使う
3. [Sharingbuttons.io](https://sharingbuttons.io/)を使う

パッと検索して考えた結果、上記3つの選択肢が候補に上がりました。その後、色々と検討したのですが、

1.はCSSのデザイン周りもコピーしないといけないので面倒。

2.はJavascriptまで使用してやり過ぎ。

結論として「3. Sharingbuttons.ioを使う」のが1番手軽で楽でした。

## Sharingbuttons.ioを使う
今回変更する箇所は下記の通りです。

```
.
├── config.toml
└── themes/
    └── hugo-notepadium
        ├── assets
        │   ├── css
        │   │   └── font.css（無ければ新規作成）
        └── layouts
            └── partials
                ├── article-labels.html
                └── share.html (新規作成)
```

「font.css」は[「hugo/notepadium」にカスタムCSSとfontawesomeの導入](https://amezou.com/posts/2020/03/13/custom-css/)の記事で作成したカスタムCSSです。

もしカスタムCSSが無ければ今回新たに作成しましょう！好きな名前のファイルでOKです！

### config.tomlの変更
[params]配下にtwitterUserを追加。この際「@」をつけ忘れないように！

```toml
[params]
...
twitterUser = "@amezousan"
```

もしカスタムCSSの設定をしてない場合は下記を追加。

```toml
[params.assets]
css = ["css/font.css"]
```

### SNS素材をコピー、貼り付け
1. [Sharingbuttons.io](https://sharingbuttons.io/)にアクセス
2. 自分が欲しい大きさとデザインを選択。今回はTwitter & Facebookを選択。「Text」には後で分かりやすいように短い文字を入力。
{{< figure src="/images/2020/03-15-sns-share-01.png" >}}
3. **右側のCSS部分を全てコピーし、font.cssに貼り付ける**
{{< figure src="/images/2020/03-15-sns-share-02.png" >}}

- themes/hugo-notepadium/assets/css/font.css

```css
.article-container p { font-size: 18px; line-height: 2 ; padding:16px 0; margin: 0;}
h1,h2,h3,h4,h5,h6 {padding-top: 16px;}

.resp-sharing-button__link,
.resp-sharing-button__icon {
  display: inline-block
...
```

4. Sharingbuttons.ioの**左側のHTML部分を全てコピーし、share.htmlファイルを作成**

- themes/hugo-notepadium/layouts/partials/share.html

```html
<!-- Sharingbutton Facebook -->
<a class="resp-sharing-button__link" href="https://facebook.com/sharer/sharer.php?u=http%3A%2F%2Fsharingbuttons.io" target="_blank" rel="noopener" aria-label="">
  <div class="resp-sharing-button resp-sharing-button--facebook resp-sharing-button--small"><div aria-hidden="true" class="resp-sharing-button__icon resp-sharing-button__icon--solid">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M18.77 7.46H14.5v-1.9c0-.9.6-1.1 1-1.1h3V.5h-4.33C10.24.5 9.5 3.44 9.5 5.32v2.15h-3v4h3v12h5v-12h3.85l.42-4z"/></svg>
    </div>
  </div>
</a>

<!-- Sharingbutton Twitter -->
<a class="resp-sharing-button__link" href="https://twitter.com/intent/tweet/?text=text&amp;url=http%3A%2F%2Fsharingbuttons.io" target="_blank" rel="noopener" aria-label="">
  <div class="resp-sharing-button resp-sharing-button--twitter resp-sharing-button--small"><div aria-hidden="true" class="resp-sharing-button__icon resp-sharing-button__icon--solid">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M23.44 4.83c-.8.37-1.5.38-2.22.02.93-.56.98-.96 1.32-2.02-.88.52-1.86.9-2.9 1.1-.82-.88-2-1.43-3.3-1.43-2.5 0-4.55 2.04-4.55 4.54 0 .36.03.7.1 1.04-3.77-.2-7.12-2-9.36-4.75-.4.67-.6 1.45-.6 2.3 0 1.56.8 2.95 2 3.77-.74-.03-1.44-.23-2.05-.57v.06c0 2.2 1.56 4.03 3.64 4.44-.67.2-1.37.2-2.06.08.58 1.8 2.26 3.12 4.25 3.16C5.78 18.1 3.37 18.74 1 18.46c2 1.3 4.4 2.04 6.97 2.04 8.35 0 12.92-6.92 12.92-12.93 0-.2 0-.4-.02-.6.9-.63 1.96-1.22 2.56-2.14z"/></svg>
    </div>
  </div>
</a>
```

ここでは`<a>`タグのhrefで、あなたのウェブサイトに適した値を使う必要があるので変更します。

- facebookのリンク
  - 元の`href`の値を下記に変更

```html

href="https://facebook.com/sharer/sharer.php?u={{ .Permalink | absURL }}"

```

> [.Permalink](https://gohugo.io/content-management/urls/#permalinks)はそのページの相対パス(/path)を作成

> [absURL](https://gohugo.io/functions/absurl/)は受け取った値を元に絶対パス(http://example/path)を作成。

- twitterのリンク
  - 元の`href`の値を下記に変更

```html

href="https://twitter.com/intent/tweet/?text={{ .Title }}｜{{ .Site.Params.twitterUser }}&url={{ .Permalink | absURL }}"

```

> Hugoではグローバル変数([Site](https://gohugo.io/variables/site/#the-siteparams-variable))が利用できます。config.tomlで設定した[param]のtwitterUserを呼び出すには`{{ .Site.Params.twitterUser }}`と指定します。


センター寄せにするための`<div align=center>`も追加して完成です。

- themes/hugo-notepadium/layouts/partials/share.html

```html
<div align=center>
<!-- Sharingbutton Facebook -->
<a class="resp-sharing-button__link" href="https://facebook.com/sharer/sharer.php?u={{ .Permalink | absURL }}" target="_blank" rel="noopener" aria-label="">
  <div class="resp-sharing-button resp-sharing-button--facebook resp-sharing-button--small"><div aria-hidden="true" class="resp-sharing-button__icon resp-sharing-button__icon--solid">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M18.77 7.46H14.5v-1.9c0-.9.6-1.1 1-1.1h3V.5h-4.33C10.24.5 9.5 3.44 9.5 5.32v2.15h-3v4h3v12h5v-12h3.85l.42-4z"/></svg>
    </div>
  </div>
</a>

<!-- Sharingbutton Twitter -->
<a class="resp-sharing-button__link" href="https://twitter.com/intent/tweet/?text={{ .Title }}｜{{ .Site.Params.twitterUser }}&url={{ .Permalink | absURL }}" target="_blank" rel="noopener" aria-label="">
  <div class="resp-sharing-button resp-sharing-button--twitter resp-sharing-button--small"><div aria-hidden="true" class="resp-sharing-button__icon resp-sharing-button__icon--solid">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M23.44 4.83c-.8.37-1.5.38-2.22.02.93-.56.98-.96 1.32-2.02-.88.52-1.86.9-2.9 1.1-.82-.88-2-1.43-3.3-1.43-2.5 0-4.55 2.04-4.55 4.54 0 .36.03.7.1 1.04-3.77-.2-7.12-2-9.36-4.75-.4.67-.6 1.45-.6 2.3 0 1.56.8 2.95 2 3.77-.74-.03-1.44-.23-2.05-.57v.06c0 2.2 1.56 4.03 3.64 4.44-.67.2-1.37.2-2.06.08.58 1.8 2.26 3.12 4.25 3.16C5.78 18.1 3.37 18.74 1 18.46c2 1.3 4.4 2.04 6.97 2.04 8.35 0 12.92-6.92 12.92-12.93 0-.2 0-.4-.02-.6.9-.63 1.96-1.22 2.56-2.14z"/></svg>
    </div>
  </div>
</a>
</div>
```

5. 「article-labels.html」ファイルに「sns.html」を読み込ませます。

- themes/hugo-notepadium/layouts/partials/article-labels.html

```html

{{- partial "share.html" . -}}
{{- if or .Params.categories .Params.tags -}}

```

> [partial](https://gohugo.io/templates/partials/#use-partials-in-your-templates)機能を使うとpartialsフォルダ以下に存在するファイルを読み込む際にパスを省略できます。

# 完成品

下記のように表示されれば完成です！

{{< figure src="/images/2020/03-15-sns-share-03.png" >}}
