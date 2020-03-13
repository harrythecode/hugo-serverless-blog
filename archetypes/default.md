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