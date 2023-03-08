FROM debian:bullseye-slim AS base

RUN addgroup --system --gid 101 nginx && \
    adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    ca-certificates \
    wget \
    libssl-dev \
    zlib1g-dev \
    libpcre3-dev \
    make \
    git \
    gcc \
    && \
    git clone --depth 1 https://github.com/google/ngx_brotli ./ngx_brotli && \
    cd ./ngx_brotli && git submodule update --init --recursive && cd .. && \
    wget https://github.com/alibaba/tengine/archive/refs/tags/2.4.0.tar.gz && \
    tar xvf 2.4.0.tar.gz && rm -rf 2.4.0.tar.gz && \
    cd tengine-2.4.0 && \
    ./configure --prefix=/etc/nginx \
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
	--with-compat \
	--with-file-aio \
	--with-threads \
    --with-pcre-jit \
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
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
    --add-module=modules/ngx_http_upstream_check_module \
    --add-module=modules/ngx_http_upstream_dynamic_module \
    --add-module=../ngx_brotli \
    && \
    make && make install && \
    cd .. \
    rm -rf tengine-2.4.0

FROM debian:bullseye-slim

RUN addgroup --system --gid 101 nginx && \
    adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    libssl1.1 \
    zlib1g \
    libpcre3 \
    && \
    rm -r /var/lib/apt/lists/* && \
    mkdir -p /var/log/nginx/ && \
    mkdir -p /var/cache/nginx && \
    # forward request and error logs to docker log collector
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY --from=base /usr/sbin/nginx /usr/sbin
COPY --from=base /etc/nginx /etc/nginx
CMD ["nginx", "-g", "daemon off;"]