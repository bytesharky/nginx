#!/bin/sh
set -e

if [ -z "$1" ]; then
  echo "用法: $0 <TAG>"
  exit 1
fi

cd "$(dirname "$0")" || exit 1

# ===== Variables =====
TAG=$1
IMAGE_NAME=sharky-nginx
REGISTRY=ccr.ccs.tencentyun.com/sharky

echo "是否为最新版本:"
echo "1) 是(Yes)"
echo "2) 否(No)"
while true; do
    read -p "Enter choice (Y/N, default Y): " yn
    yn=${yn:-Y}
    case $yn in
        [Yy]* ) IS_LATEST=Y; break;;
        [Nn]* ) IS_LATEST=N; break;;
        * ) ;;
    esac
done

echo "是否推送到仓库:"
echo "1) 是(Yes)"
echo "2) 否(No)"
while true; do
    read -p "Enter choice (Y/N, default Y): " yn
    yn=${yn:-Y}
    case $yn in
        [Yy]* ) IS_PUSH=Y; break;;
        [Nn]* ) IS_PUSH=N; break;;
        * ) ;;
    esac
done

echo ">>> 构建镜像: $IMAGE_NAME:$TAG"
docker build --build-arg BUILD_DATE="$(date)" --build-arg BRANCH="nginx-$TAG" -t $IMAGE_NAME:$TAG .

echo ">>> 打标签..."
docker tag $IMAGE_NAME:$TAG $REGISTRY/$IMAGE_NAME:$TAG

if [ "${IS_LATEST}" = "Y" ]; then
  docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
  docker tag $IMAGE_NAME:$TAG $REGISTRY/$IMAGE_NAME:latest
fi

if [ "${IS_PUSH}" = "Y" ]; then
  echo ">>> 推送镜像..."
  docker push $REGISTRY/$IMAGE_NAME:$TAG

  if [ "${IS_LATEST}" = "Y" ]; then
    docker push $REGISTRY/$IMAGE_NAME:latest
  fi
fi

echo ">>> 完成"
