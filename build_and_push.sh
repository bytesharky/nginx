#!/bin/sh
set -e

if [ -z "$1" ]; then
  echo "用法: $0 <TAG>"
  exit 1
fi

cd "$(dirname "$0")" || exit 1

TAG=$1
IMAGE_NAME=sharky-nginx
REGISTRY=ccr.ccs.tencentyun.com/sharky

echo ">>> 构建镜像: $IMAGE_NAME:$TAG"
docker build --build-arg BUILD_DATE="$(date)" -t $IMAGE_NAME:$TAG .

echo ">>> 打标签..."
docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
docker tag $IMAGE_NAME:$TAG $REGISTRY/$IMAGE_NAME:$TAG
docker tag $IMAGE_NAME:$TAG $REGISTRY/$IMAGE_NAME:latest

echo ">>> 推送镜像..."
docker push $REGISTRY/$IMAGE_NAME:$TAG
docker push $REGISTRY/$IMAGE_NAME:latest

echo ">>> 完成"
