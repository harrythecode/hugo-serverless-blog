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
    echo "How to use: -b <S3 Bucket Name>"
    exit 1
fi

FILES=()
for i in $( rsync --itemize-changes --checksum --dry-run --delete --recursive public/ prev_public/|awk '{print $2}' ); do
    FILES+=( "$i" )
done
echo "${FILES[@]}"

CMDS=()
for i in "${FILES[@]}"; do
    CMDS+=("--include=$i")
done
echo ${CMDS[@]}

echo "${CMDS[@]}" | xargs aws s3 sync ./public s3://${S3_BUCKET}/public --delete --exclude "*"