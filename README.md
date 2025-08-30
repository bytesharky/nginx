# sharky nginx

##

### 注意：此Nginx非官方版，此版可隐藏Server头

#### Docker构建

```bash
# 1. 克隆镜像(仅docker分支)
git clone --branch docker --single-branch --depth 1 https://github.com/bytesharky/nginx.git && cd nginx

# 2. 构建镜像
docker build -t sharky-nginx:latest .

# 3. 启动容器
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


# 或者拉取我构建好的镜像
docker pull ccr.ccs.tencentyun.com/sharky/sharky-nginx
```
