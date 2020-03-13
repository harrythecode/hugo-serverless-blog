#!/bin/sh

dir_path="content/posts"
for f in $(find $dir_path -name '*.md'); do
	python create_meta_image.py $f
done