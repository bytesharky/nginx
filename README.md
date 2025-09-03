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

### 特性功能

为了解决 `acme.sh` 运行在容器中，不便于让nginx重新加载的情况，一些可行的方式是

1. 挂载 /var/run/docker.sock (容器可能获得宿主机 root 权限)
2. Nginx 扩展 `ngx_http_api_module` (商业版扩展)
3. Webhook

最终决定用一个简单`webhook`，选择用 c 语言编写，因为不需要安装额外的运行环境，而且编译 Nginx 时，已经部署了 c 语言编译环境。

该服务通过简单的 HTTP 服务监听指定的端口和路径，对有效请求执行“`nginx -s reload`”。

`acme.sh` 成功更新证书后，可以通过 `curl` 调用该服务重新加载 Nginx，官方的 `acme.sh` 镜像已经包含 `cur`。

监听端口和路径可以通过 Docker 环境变量配置：

```bash
RELOAD_PORT=8080     #默认值：8080
RELOAD_PATH=/reload  #默认值：/reload
```

出于安全原因，请勿将此服务暴露在公共互联网上。

默认情况我已经在Dockerfile中将它编译到nginx镜像
