### 注意：此Nginx非官方版，此版可隐藏Server头。

#### 在官方的Nginx中，可在配置文件中使用如下配置，来隐藏Server头的Nginx版本信息。

``` nginx
http {
  ...
  server_tokens  off;
  ...
}
```
#### 但是Server字段依然显示正在使用的是Nginx服务器。

#### 然而我并不想显示包括Nginx的一些服务器相关信息，所以我修改了Nginx的代码。

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

![这是一张示例图片](https://github.com/bytesharky/nginx/blob/nginx-1.26/images/1720182600960.jpg?raw=true)

当`server_tokens  off;`时

![这是一张示例图片](https://github.com/bytesharky/nginx/blob/nginx-1.26/images/1720182656168.jpg?raw=true)

当`server_tokens  hide;`时

![这是一张示例图片](https://github.com/bytesharky/nginx/blob/nginx-1.26/images/1720182890661.jpg?raw=true)
