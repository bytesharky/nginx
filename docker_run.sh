#!/bin/sh
set -e

ROOT_PATH="/data/docker/nginx"
IMAGE_NAME="sharky-nginx"
CONTAINER_NAME="sharky-nginx"
TAG="latest"

if [ ! -d "$ROOT_PATH" ]; then
  mkdir -p "$ROOT_PATH/conf"
  mkdir -p "$ROOT_PATH/logs"
fi

if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "$MSG_EXIST $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME"
fi

docker run -d \
  -p 80:80 \
  -p 443:443/tcp \
  -p 443:443/udp \
  -e TZ=Asia/Shanghai \
  --name "$CONTAINER_NAME" \
  -v $ROOT_PATH/conf:/etc/nginx \
  -v $ROOT_PATH/logs:/var/log/nginx \
  "$IMAGE_NAME:$TAG"
