FROM debian:buster as builder
RUN apt-get update && apt-get -y install curl wget libssl-dev libpcre3-dev zlib1g-dev tar make gcc git 
WORKDIR /builder
RUN wget https://openresty.org/download/nginx-1.19.3.tar.gz && tar -zxvf nginx-1.19.3.tar.gz && rm nginx-1.19.3.tar.gz
RUN git clone https://github.com/chobits/ngx_http_proxy_connect_module.git && \
    wget https://raw.githubusercontent.com/chobits/ngx_http_proxy_connect_module/master/patch/proxy_connect_rewrite_1018.patch 
RUN wget https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v0.3.1.tar.gz && tar -zxvf v0.3.1.tar.gz
RUN wget https://github.com/openresty/lua-nginx-module/archive/refs/tags/v0.10.15.tar.gz && tar -zxvf v0.10.15.tar.gz
RUN wget https://github.com/openresty/luajit2/archive/refs/tags/v2.1-20210510.tar.gz && tar -zxvf v2.1-20210510.tar.gz
RUN cd luajit2-2.1-20210510 && make install
RUN rm -f *.tar.gz
RUN cd nginx-1.19.3 && \
    patch -p1  < ../proxy_connect_rewrite_1018.patch
RUN cd nginx-1.19.3 && \
    LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.1 ./configure --add-module=/builder/lua-nginx-module-0.10.15 --add-module=/builder/ngx_devel_kit-0.3.1 --add-module=/builder/ngx_http_proxy_connect_module --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-1.19.8/debian/debuild-base/nginx-1.19.8=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' && \
     make && make install

RUN apt update && \
    apt install -y python3 python3-dev libffi6 libffi-dev libssl-dev curl build-essential procps gettext-base&& \
    curl -L 'https://bootstrap.pypa.io/get-pip.py' | python3 && \
    pip install -U cffi certbot && \
    apt remove --purge -y python3-dev build-essential libffi-dev libssl-dev curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN useradd -m nginx
RUN mkdir -p /var/cache/nginx/client_temp && chown nginx:nginx /var/cache/nginx/client_temp
# Copy in scripts for certbot
COPY src/scripts/ /scripts
RUN chmod +x /scripts/*.sh

# Add /scripts/startup directory to source more startup scripts
RUN mkdir -p /scripts/startup

# Copy in default nginx configuration (which just forwards ACME requests to
# certbot, or redirects to HTTPS, but has no HTTPS configurations by default).
RUN rm -f /etc/nginx/conf.d/*
COPY src/nginx_conf.d/ /etc/nginx/conf.d/
COPY src/auth.lua /etc/nginx/auth.lua
COPY src/nginx.conf /etc/nginx/nginx.conf
RUN wget https://github.com/openresty/lua-resty-core/archive/refs/tags/v0.1.17.tar.gz && tar -zxvf v0.1.17.tar.gz
RUN wget https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v0.11.tar.gz && tar -zxvf v0.11.tar.gz
RUN rm -rf /var/log/nginx/* && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint.sh"]
