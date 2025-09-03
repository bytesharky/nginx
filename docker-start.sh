#!/bin/sh
set -e

# 确保 nginx 用户和组存在
if ! getent group nginx > /dev/null; then
    addgroup -S nginx
fi
if ! getent passwd nginx > /dev/null; then
    adduser -S -G nginx -s /sbin/nologin nginx
fi

NGINX_CONF="/etc/nginx/nginx.conf"

# 如果 nginx.conf 不存在，生成默认配置
if [ ! -f "$NGINX_CONF" ]; then
    echo "nginx.conf not found, generating default..."
    mkdir -p /etc/nginx/conf.d
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/sites-available
    cp -n /usr/share/nginx/conf/* /etc/nginx/
    cat > "$NGINX_CONF" <<'EOF'
user nginx;
worker_processes auto;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout 65;

    server {
        listen       80;
        server_name  localhost;
        root /usr/share/nginx/html;

        location / {
            index index.html index.htm;
        }
    }

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*.conf;
}
EOF
fi

# 确保日志目录存在
mkdir -p /var/log/nginx /var/cache/nginx

# 启动 reload-server 在后台
RELOAD_PORT=${RELOAD_PORT:-8080}
RELOAD_PATH=${RELOAD_PATH:-/reload}
/usr/sbin/reload-server &

# 启动 nginx 前台
exec /usr/sbin/nginx -g "daemon off;"
