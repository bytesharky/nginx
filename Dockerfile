# =======================
# Stage 1: Base builder
# =======================
FROM alpine:3.22 AS base-builder

# 安装编译依赖
RUN apk add --no-cache \
    build-base \
    pcre2-dev \
    zlib-dev \
    openssl-dev \
    perl-dev \
    git \
    wget \
    tar \
    curl \
    linux-headers \
    cmake \
    cargo \
    rust \
    nasm

WORKDIR /usr/src

# =======================
# Stage 2: Clone & Build
# =======================
FROM base-builder AS builder

ARG BUILD_DATE
ARG BRANCH

# =======================
# clone Nginx
# =======================
# 确保每次构建重新克隆代码
RUN echo "Build date: ${BUILD_DATE}" && \
    rm -rf sharky-nginx 2>/dev/null || true

# 最新版本
# RUN git clone --depth 1 https://github.com/bytesharky/nginx sharky-nginx

# 指定版本
RUN git clone --depth 1 --branch ${BRANCH} https://github.com/bytesharky/nginx sharky-nginx

# 国内可用源
# RUN git clone --depth 1 --branch ${BRANCH} https://gitee.com/bytesharky/nginx sharky-nginx

WORKDIR /usr/src/sharky-nginx

# =======================
# 编译 Nginx
# =======================
RUN chmod +x ./configure && \
     ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    \
    --with-compat \
    --with-file-aio \
    --with-threads \
    \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_v3_module \
    \
    --with-mail \
    --with-mail_ssl_module \
    \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    \
    --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
    --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
    && make && make install && \
    mkdir -p /usr/lib/nginx

# =======================
# 编译 Nginx 重载服务工具
# =======================

COPY reload-server.c /usr/src/

WORKDIR /usr/src/

RUN gcc reload-server.c -o reload-server

# =======================
# Stage 3: Minimal runtime
# =======================
FROM alpine:3.22

ARG BUILD_DATE
LABEL build.date="${BUILD_DATE}"

# 确保 www-data 存在
RUN set -eux; \
    if getent passwd www-data >/dev/null; then \
        deluser www-data; \
    fi; \
    if getent group www-data >/dev/null; then \
        delgroup www-data; \
    fi; \
    addgroup -g 33 -S www-data; \
    adduser -u 33 -S -D -H -s /sbin/nologin -G www-data www-data

# 添加运行时依赖
RUN apk add --no-cache \
    pcre2 \
    zlib \
    openssl \
    curl \
    ca-certificates && \
    adduser -D -S -H -s /sbin/nologin nginx && \
    mkdir -p /var/log/nginx /var/cache/nginx /etc/nginx/conf.d

# 拷贝编译好的 nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/lib/nginx /usr/lib/nginx
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/src/reload-server /usr/sbin/reload-server

# 拷贝默认配置
COPY --from=builder /usr/src/sharky-nginx/html /usr/share/nginx/html
COPY --from=builder /usr/src/sharky-nginx/conf /usr/share/nginx/conf
COPY --from=builder /usr/src/sharky-nginx/docker-start.sh /start.sh

# 挂载点
VOLUME ["/etc/nginx", "/var/log/nginx"]

EXPOSE 443/tcp 443/udp 80/tcp

STOPSIGNAL SIGQUIT
RUN chmod +x /start.sh
CMD ["/start.sh"]
