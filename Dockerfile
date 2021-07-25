FROM debian:buster as builder
RUN apt-get update && apt-get -y install curl wget libssl-dev libpcre3-dev zlib1g-dev tar make gcc git
WORKDIR /builder
RUN wget http://nginx.org/download/nginx-1.19.2.tar.gz && tar -zxvf nginx-1.19.2.tar.gz && rm nginx-1.19.2.tar.gz
RUN git clone https://github.com/chobits/ngx_http_proxy_connect_module.git && \
    wget https://raw.githubusercontent.com/chobits/ngx_http_proxy_connect_module/master/patch/proxy_connect_rewrite_1018.patch
RUN cd nginx-1.19.2 && \
    patch -p1 < ../proxy_connect_rewrite_1018.patch
RUN cd nginx-1.19.2 && \
    ./configure --add-module=/builder/ngx_http_proxy_connect_module --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-1.19.8/debian/debuild-base/nginx-1.19.8=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' && \
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
COPY src/nginx.conf /etc/nginx/nginx.conf
ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint.sh"]
