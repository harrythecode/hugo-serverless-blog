#!/bin/bash

while getopts b: option
do
case "${option}"
in
    b) S3_BUCKET=${OPTARG};;
esac
done

echo "Target: ${S3_BUCKET}"

if [ -z ${S3_BUCKET} ]
then
    echo "How to use: -s3 <S3 Bucket Name>"
    exit 1
fi

FILES=()
for i in $( git status -s | sed 's/\s*[a-zA-Z"?]\+ \(.*\)/\1/' | sed 's/"//g' | grep "public/"); do
    FILES+=( "$i" )
done
echo "${FILES[@]}"

CMDS=()
for i in "${FILES[@]}"; do
    CMDS+=("--include=$i""*")
done
echo ${CMDS[@]}

echo "${CMDS[@]}" | xargs aws s3 sync . s3://${S3_BUCKET} --dryrun --delete --exclude "*" --profile terraform-init-role