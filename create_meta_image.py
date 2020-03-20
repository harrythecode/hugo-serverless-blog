#!/usr/bin/env python
# -*- coding: utf-8 -*-
from PIL import ImageFont, ImageDraw, Image
import sys
import yaml
import os.path
from os import path

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
if (path.exists(target)):
    print("skipping:%s because the thumbnail already exists." % target)
    exit(0)
else:
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