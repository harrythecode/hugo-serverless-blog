---
title : "HugoでTwitterカード画像を自動生成する方法"
date  : 2020-03-11T13:55:46+01:00
draft : false
tags  : [
    "hugo",
    "hugo-custom"
]
categories: [
    "Twitterカード画像の自動生成化",
]
meta_image  : "/thumbnails/2020-03-11-sns-image.png"
description : ""
---

# 今回やりたいこと

Hugoで記事ごとにTwitterカードを生成するのが面倒なので自動化したい。

## 参考にしたもの
[twitterカード画像自動生成機能](https://encr.jp/blog/categories/twitter%E3%82%AB%E3%83%BC%E3%83%89%E7%94%BB%E5%83%8F%E8%87%AA%E5%8B%95%E7%94%9F%E6%88%90%E6%A9%9F%E8%83%BD/) - 著者: るなさん ([Twitter](https://twitter.com/engineergirl_w))

## 進め方
1. (Python) markdownからTwitterカード画像を作成
2. (Shell) 特定フォルダに画像コンテンツを作成
3. (Hugo) コマンド実行で静的コンテンツを作成
4. (AWS CLI) s3にコンテンツアップロード

今回利用するコンテンツの構成は以下の通り

```
├── content
│   └── posts
│       └── 2020
│           └── 03
│               ├── 07
│               │   └── how-to-set-up-serverless-blog.md
│               ├── 08
│               │   └── cloud-engineer-must-use-terraform.md
│               ├── 10
│               │   └── how-to-enable-twitter-card-in-a-hugo-theme.md
│               └── 11
│                   └── sns-image.md
├── create_images.sh
├── create_meta_image.py
```


### 1. (Python) markdownからTwitterカード画像を作成

[twitterカード画像自動生成機能④](https://encr.jp/blog/posts/20200216_lunch/) の記事のコードを少し改変

- create_meta_image.py

```py
#!/usr/bin/env python
# -*- coding: utf-8 -*-
from PIL import ImageFont, ImageDraw, Image
import sys
import yaml

def add_text_to_image(img, base_text, font_path, font_size, font_color, height, width, line=1, max_length=700, max_height=420):
    font = ImageFont.truetype(font_path, font_size)
    draw = ImageDraw.Draw(img)
    lineCnt = 1
    base_text = base_text.strip()
    base_text = base_text.replace("\n\n", "\n")
    base_text = base_text[0:150]
    break_flg = False
    for lineCnt in range(line):
        text = base_text.split("\n")[0]
        position = (width, height)
        if len(text) == 0:
            break
        if lineCnt == line - 1 or \
                height + draw.textsize(text, font=font)[1] > max_height:
            if draw.textsize(text, font=font)[0] > max_length:
                # テキストの長さがmax_lengthより小さくなるまで、1文字ずつ削っていく
                while draw.textsize(text + u'...', font=font)[0] > max_length:
                    text = text[:-1]
                text = text + u'...'
                break_flg = True
        else:
            while draw.textsize(text, font=font)[0] > max_length:
                text = text[:-1]
        base_text = base_text.replace(text, "")
        base_text = base_text.strip()
        height = height + draw.textsize(text, font=font)[1]
        draw.text(position, text, font_color, font=font)
        if break_flg:
            break

    return img

target = sys.argv[1]
print("target:%s" % target)

with open('%s' % target) as f:
    md          = f.read().split("---")
    header_yaml = md[1]
    body        = md[2]
    header      = yaml.load(header_yaml, Loader=yaml.FullLoader)
    title       = header["title"]

base_image_path = 'static/thumbnails/base.png'
base_img        = Image.open(base_image_path).copy()

text       = title
font_path  = "static/fonts/hiragino-w7.ttc"
font_size  = 52
font_color = (0, 51, 102)
height     = 180
width      = 100
line       = 2
img        = add_text_to_image(base_img, text, font_path, font_size, font_color, height, width, line)

text       = u"世の中のイケてる技術を紹介していきます"
font_path  = "static/fonts/hiragino-w7.ttc"
font_size  = 28
font_color = (160, 160, 160)
height     = 410
width      = 100
line       = 1
img        = add_text_to_image(base_img, text, font_path, font_size, font_color, height, width, line)

# 画像のパスをきれいにします
# (e.g.,) target: content/posts/2020-03-11-this-is-a-pen.md
# -> 2020-03-11-this-is-a-pen
target = target.replace("content/posts/", "")
target = target.replace("/", "-")
target = target.replace(".md", "")

img.save("static/thumbnails/%s.png" % target)
```

ちなみにフォントはMac標準のものを使用
```bash
$ ls /System/Library/Fonts/
...
ヒラギノ角ゴシック W7.ttc
```

ベースのイメージはこんな感じ
{{< figure src="/thumbnails/base.png" width="400" title="ベースイメージ" >}}

### 2. (Shell) 特定フォルダに画像コンテンツを作成

[twitterカード画像自動生成機能⑤](https://encr.jp/blog/posts/20200217_morning/)の記事を参考に。

```bash
#!/bin/sh

dir_path="content/posts"
for f in $(find $dir_path -name '*.md'); do
	echo $f
done
```

```bash
$ ./create_images.sh
content/posts/2020/03/11/sns-image.md
content/posts/2020/03/10/how-to-enable-twitter-card-in-a-hugo-theme.md
content/posts/2020/03/07/how-to-set-up-serverless-blog.md
content/posts/2020/03/08/cloud-engineer-must-use-terraform.md
```

シェルの中で「`python create_meta_image.py 2020/03/08/cloud-engineer-must-use-terraform.md`」のように呼び出します。

```bash
#!/bin/sh

dir_path="content/posts"
for f in $(find $dir_path -name '*.md'); do
	python create_meta_image.py $f
done
```

```
$ ./create_images.sh
target:content/posts/2020/03/11/sns-image.md
target:content/posts/2020/03/10/how-to-enable-twitter-card-in-a-hugo-theme.md
target:content/posts/2020/03/07/how-to-set-up-serverless-blog.md
target:content/posts/2020/03/08/cloud-engineer-must-use-terraform.mds
```

### 3. (Hugo) コマンド実行で静的コンテンツを作成

「hugo new (タイトル)」コマンドを実行した際に作られるデフォルトの記事フォーマットを下記の通り変更。

- archetypes/default.md

```yaml
---
title : "{{ replace .Name "-" " " | title }}"
date  : {{ .Date }}
draft : false
tags  : [
    "tag1",
    "tag2",
    "tag3",
]
categories: [
    "category1",
    "category2"
]
meta_image  : "/thumbnails/{{ dateFormat "2006-01-02" .Date }}-{{ .Name }}.png"
description : ""
---
```

試しに作成。

```bash
$ hugo new posts/2020/03/11/this-is-a-pen.md
./content/posts/2020/03/11/this-is-a-pen.md created
$ cat content/posts/2020/03/11/this-is-a-pen.md
---
title : "This Is a Pen"
date  : 2020-03-11T23:45:09+01:00
draft : false
tags  : [
    "tag1",
    "tag2",
    "tag3",
]
categories: [
    "category1",
    "category2"
]
meta_image  : "/thumbnails/2020-03-11-this-is-a-pen.png"
description : ""
---
```

コンテンツを作成

```
$ ./create_images.sh && hugo
target:content/posts/2020/03/11/this-is-a-pen.md
target:content/posts/2020/03/11/sns-image.md
target:content/posts/2020/03/10/how-to-enable-twitter-card-in-a-hugo-theme.md
target:content/posts/2020/03/07/how-to-set-up-serverless-blog.md
target:content/posts/2020/03/08/cloud-engineer-must-use-terraform.md

                   | EN
-------------------+-----
  Pages            | 51
  Paginator pages  |  0
  Non-page files   |  0
  Static files     | 18
  Processed images |  0
  Aliases          | 24
  Sitemaps         |  1
  Cleaned          |  0

Total in 106 ms
```

次のようなコンテンツ構成になりました。

```
├── content
│   └── posts
│       └── 2020
│           └── 03
│               ├── 07
│               │   └── how-to-set-up-serverless-blog.md
│               ├── 08
│               │   └── cloud-engineer-must-use-terraform.md
│               ├── 10
│               │   └── how-to-enable-twitter-card-in-a-hugo-theme.md
│               └── 11
│                   ├── this-is-a-pen.md
│                   └── sns-image.md
├── create_images.sh
├── create_meta_image.py
├── static
│   ├── fonts
│   │   └── hiragino-w7.ttc
│   ├── images
│   │   ├── 2020-03-06-03-serverless-blog-overview.png
│   │   ├── 2020-03-07-01-speed.png
│   │   ├── 2020-03-07-02-speed-google.png
│   │   ├── 2020-03-07-03-iam.png
│   │   ├── 2020-03-10-01.png
│   │   └── 2020-03-10-02.png
│   └── thumbnails
│       ├── 2020-03-07-how-to-set-up-serverless-blog.png
│       ├── 2020-03-08-cloud-engineer-must-use-terraform.png
│       ├── 2020-03-10-how-to-enable-twitter-card-in-a-hugo-theme.png
│       ├── 2020-03-11-sns-image.png
│       ├── 2020-03-11-this-is-a-pen.png
│       ├── base.png
│       └── default.png
```

「static」フォルダに入ってるコンテンツは「hugo」コマンドを実行した際に「public」フォルダ配下に直接配置されます。

そのため、わざわざ生成したファイルをどこかに移す作業が不要となります。

現在のスクリプトはMarkdown記事のヘッダ内で「draft: true」(下書き中)としていた場合でも画像を自動生成してしまうので注意して下さい。

### 4. (AWS CLI) s3にコンテンツアップロード

[【保存版】爆速！サーバレスブログの作り方(1/2)【Hugo+AWS+Terraform】](https://note.com/amezousan/n/n1063cdc9524f)の記事を既に設定済みの方は下記コマンドでアップロード可能です。

```bash
$ AWS_PROFILE=terraform-init-user aws s3 sync --profile terraform-init-role --delete ./public/ s3://(あなたのS3_BUCKET名)/public/
```

# 完成品

{{< figure src="/images/2020/03-12-sns-image-01.png" width="400" title="自動生成されたTwitterカード" >}}

やっと記事を書くことだけに集中できます！
