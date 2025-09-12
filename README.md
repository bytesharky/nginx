# sharky nginx

##

### 注意：此Nginx非官方版，此版可隐藏Server头

#### 在官方的Nginx中，可在配置文件中使用如下配置，来隐藏Server头的Nginx版本信息

``` nginx
http {
  ...
  server_tokens  off;
  ...
}
```

#### 但是Server字段依然显示正在使用的是Nginx服务器

#### 然而我并不想显示包括Nginx的一些服务器相关信息，所以我修改了Nginx的代码，使其可以隐藏甚至修改Server头

### 使用示例

``` nginx
http {
    ...
    # 官方版本server_tokens可以设置为
    # on：   这是默认值，在 Server 头中包含完整的nginx版本信息。
    # off：  设置为 off 后，Server 头仅显示nginx，不显示版本信息。
    # build：设置为 build 后，Server 头中包含编译时指定的构建值。
    # 
    # 这里注意，此Nginx在官方版基础上增加了
    # hide： 设置为 hide 后，http响应头中将不会有Server头。
    server_tokens  hide;
    ...
    location / {
        proxy_pass http://backend_server;
        ...
        # 通过官方支持的proxy_hide_header指令
        # 隐藏varnish、nodejs、tomact、apache等相关的响应头
        proxy_hide_header Via;
        proxy_hide_header X-Varnish;
        proxy_hide_header X-Powered-By;
        ...
    }
    ...
}
```

#### 下面是效果演示

当`server_tokens  on;`或未配置时

![这是一张示例图片](/images/1720182600960.jpg?raw=true)

当`server_tokens  off;`时

![这是一张示例图片](/images/1720182656168.jpg?raw=true)

当`server_tokens  hide;`时

![这是一张示例图片](/images/1720182890661.jpg?raw=true)

#### 修改Server头的实现

```nginx
http {
    ...
    # 隐藏原有的Server头
    server_tokens  hide;

    # 添加自定义的Server头
    add_header     "Server"  "SharkyServer";
    ...
}
```

#### 具体修改内容参见

[Nginx隐藏Server头](../../commit/6ba6f6d39541d69442a1297be1e7f309f9d74d63)

#### Docker构建

```bash
# 1. 克隆镜像(仅docker分支)并构建镜像
git clone --branch docker --single-branch --depth 1 https://github.com/bytesharky/nginx.git && cd nginx
docker build -t sharky/nginx:latest .

# 2. 或者拉取我构建好的镜像
docker pull ccr.ccs.tencentyun.com/sharky/nginx:latest
docker tag ccr.ccs.tencentyun.com/sharky/nginx:latest sharky/nginx:latest

# 3. 启动容器
ROOT_PATH="/data/docker/nginx"
docker run -d \
  -p 80:80 \
  -p 443:443/tcp \
  -p 443:443/udp \
  -e TZ=Asia/Shanghai \
  --name nginx \
  -v $ROOT_PATH/conf:/etc/nginx \
  -v $ROOT_PATH/logs:/var/log/nginx \
  -v $ROOT_PATH/website:/var/website \
  sharky/nginx:latest

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
