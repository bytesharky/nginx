#!/bin/sh
set -e

ROOT_PATH="/data/docker/nginx"

docker run -d \
  -p 80:80 \
  -p 443:443/tcp \
  -p 443:443/udp \
  -e TZ=Asia/Shanghai \
  --name sharky-nginx \
  -v $ROOT_PATH/conf:/etc/nginx \
  -v $ROOT_PATH/logs:/var/log/nginx \
  sharky-nginx:latest
  