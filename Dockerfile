FROM rust:1.61.0-slim-bullseye AS builder

ARG NGINX_VERSION="1.21.6"
ARG NGINX_GPG_KEY="B0F4253373F8F6F510D42178520A9993A1C052F8"
ARG NGINX_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
ARG NGINX_PGP_URL="https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc"

# ARG NGINX_OTHER_PATCH="https://raw.githubusercontent.com/kn007/patch/master/nginx.patch"
# ARG NGINX_USE_OPENSSL_CRYPTO_PATCH="https://raw.githubusercontent.com/kn007/patch/master/use_openssl_md5_sha1.patch"
ARG NGINX_OTHER_WITH_QUIC_PATCH="https://raw.githubusercontent.com/kn007/patch/master/nginx_with_quic.patch"
ARG NGINX_BORINGSSL_OCSP_PATCH="https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch"

ARG ZLIB_URL="https://github.com/cloudflare/zlib.git"

# ARG OPENSSL_VERSION="1.1.1k"
# ARG OPENSSL_URL="https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
# ARG OPENSSL_EQUAL_PATCH="https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-1.1.1e-dev_ciphers.patch"
# ARG OPENSSL_CHACHA_DRAFT_PATCH="https://raw.githubusercontent.com/CarterLi/openssl-patch/master/openssl-1.1.1i-chacha_draft.patch"

ARG QUICHE_VERSION="0.14.0"
ARG QUICHE_URL="https://github.com/cloudflare/quiche.git"

ARG PCRE_VERSION="8.45"
ARG PCRE_URL="https://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz"

ARG LIBATOMIC_VERSION="7.6.12"
ARG LIBATOMIC_URL="https://github.com/ivmai/libatomic_ops/releases/download/v${LIBATOMIC_VERSION}/libatomic_ops-${LIBATOMIC_VERSION}.tar.gz"

ARG MODULE_BROTLI_URL="https://github.com/google/ngx_brotli.git"

ARG MODULE_STICKY_URL="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng.git"

ARG MODULE_HEADERS_MORE_VERSION="0.33"
ARG MODULE_HEADERS_MORE_URL="https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${MODULE_HEADERS_MORE_VERSION}.tar.gz"

ARG MODULE_HTTP_FLV_URL="https://github.com/winshining/nginx-http-flv-module.git"

ARG MODULE_FANCYINDEX_VERSION="0.5.2"
ARG MODULE_FANCYINDEX_URL="https://github.com/aperezdc/ngx-fancyindex/releases/download/v${MODULE_FANCYINDEX_VERSION}/ngx-fancyindex-${MODULE_FANCYINDEX_VERSION}.tar.xz"

ARG MODULE_SUBS_FILTER_URL="https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git"

ARG MODULE_GEOIP2_VERSION="3.3"
ARG MODULE_GEOIP2_URL="https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${MODULE_GEOIP2_VERSION}.tar.gz"

RUN set -eux \
    && apt-get update -qyy \
    && apt-get install -qyy --no-install-recommends --no-install-suggests \
        ca-certificates \
        wget \
        gnupg \
        \
        git \
        file \
        build-essential \
        cmake \
        libjemalloc-dev \
        libxslt1-dev \
        libgd-dev \
        libgeoip-dev \
        libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/* /var/log/* \
    \
    && wget -O nginx.tar.gz ${NGINX_URL} \
    && wget -O nginx.tar.gz.asc ${NGINX_PGP_URL} \
    \
    && export GNUPGHOME=$(mktemp -d); \
        for key in ${NGINX_GPG_KEY}; do \
            gpg --batch --keyserver hkps://keyserver.ubuntu.com --keyserver-options timeout=10 --recv-keys ${key} || \
            gpg --batch --keyserver hkps://pgp.surf.nl --keyserver-options timeout=10 --recv-keys ${key} || \
            gpg --batch --keyserver hkp://pgp.mit.edu --keyserver-options timeout=10 --recv-keys ${key}; \
        done \
    && gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && gpgconf --kill all \
    \
    && tar -xzvf nginx.tar.gz -C /usr/src/ \
    && rm -rf nginx* ${GNUPGHOME}

RUN set -eux \
    && cd /usr/src/nginx-${NGINX_VERSION}/ \
    \
    # zlib-cloudflare
    && git clone --depth 1 ${ZLIB_URL} \
    && ( \
            cd zlib/; \
            make -f Makefile.in distclean \
        ) \
    # \
    # OpenSSL
    # && wget -O openssl-${OPENSSL_VERSION}.tar.gz ${OPENSSL_URL} \
    # && tar -xzvf openssl-${OPENSSL_VERSION}.tar.gz \
    # && ( \
    #         cd openssl-${OPENSSL_VERSION}/; \
    #         wget -O - ${OPENSSL_EQUAL_PATCH} | patch -p1; \
    #         wget -O - ${OPENSSL_CHACHA_DRAFT_PATCH} | patch -p1 \
    #     ) \
    \
    # quiche
    && git clone --branch ${QUICHE_VERSION} --depth=1 --recurse-submodules --shallow-submodules ${QUICHE_URL} \
    \
    # PCRE
    && wget -O pcre-${PCRE_VERSION}.tar.gz ${PCRE_URL} \
    && tar -xzvf pcre-${PCRE_VERSION}.tar.gz \
    \
    # libatomic_ops
    && wget -O libatomic_ops-${LIBATOMIC_VERSION}.tar.gz ${LIBATOMIC_URL} \
    && tar -xzvf libatomic_ops-${LIBATOMIC_VERSION}.tar.gz \
    && ( \
            cd libatomic_ops-${LIBATOMIC_VERSION}/; \
            ./configure; \
            make -j $(nproc); \
            ln -s .libs/libatomic_ops.a src/libatomic_ops.a \
        ) \
    \
    # ngx_brotli
    && git clone --depth=1 --recurse-submodules --shallow-submodules ${MODULE_BROTLI_URL} \
    \
    # nginx-sticky-module-ng
    && git clone --depth 1 ${MODULE_STICKY_URL} \
    \
    # headers-more-nginx
    && wget -O headers-more-nginx-module-${MODULE_HEADERS_MORE_VERSION}.tar.gz ${MODULE_HEADERS_MORE_URL} \
    && tar -xzvf headers-more-nginx-module-${MODULE_HEADERS_MORE_VERSION}.tar.gz \
    \
    # nginx-http-flv-module
    && git clone --depth 1 ${MODULE_HTTP_FLV_URL} \
    \
    # ngx-fancyindex
    && wget -O ngx-fancyindex-${MODULE_FANCYINDEX_VERSION}.tar.xz ${MODULE_FANCYINDEX_URL} \
    && tar -xvf ngx-fancyindex-${MODULE_FANCYINDEX_VERSION}.tar.xz \
    \
    # nginx_substitutions_filter
    && git clone --depth 1 ${MODULE_SUBS_FILTER_URL} \
    \
    # ngx_http_geoip2_module
    && wget -O ngx_http_geoip2_module-${MODULE_GEOIP2_VERSION}.tar.gz ${MODULE_GEOIP2_URL} \
    && tar -xzvf ngx_http_geoip2_module-${MODULE_GEOIP2_VERSION}.tar.gz

RUN set -eux \
    && cd /usr/src/nginx-${NGINX_VERSION}/ \
    \
    # && wget -O - ${NGINX_OTHER_PATCH} | patch -p1 \
    # && wget -O - ${NGINX_USE_OPENSSL_CRYPTO_PATCH} | patch -p1 \
    && wget -O - ${NGINX_OTHER_WITH_QUIC_PATCH} | patch -p1 \
    && wget -O - ${NGINX_BORINGSSL_OCSP_PATCH} | patch -p1 \
    \
    && ./configure \
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
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module \
        --with-http_image_filter_module \
        --with-http_geoip_module \
        --with-http_slice_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-stream_geoip_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-threads \
        --with-compat \
        --with-ld-opt="-Wl,-z,relro -Wl,-z,now -fPIC -ljemalloc -lrt" \
        --with-cc-opt="-O3 -g -DTCP_FASTOPEN=23 -ffast-math -flto -fuse-ld=gold -fstack-protector-strong --param=ssp-buffer-size=4 -Wformat -Werror=format-security -fPIC -Wp,-D_FORTIFY_SOURCE=2 -Wno-deprecated-declarations" \
        --with-zlib=/usr/src/nginx-${NGINX_VERSION}/zlib \
        # --with-openssl=/usr/src/nginx-${NGINX_VERSION}/openssl-${OPENSSL_VERSION} \
        # --with-openssl-opt="zlib enable-weak-ssl-ciphers enable-ec_nistp_64_gcc_128 -ljemalloc -Wl,-flto" \
        --with-openssl=/usr/src/nginx-${NGINX_VERSION}/quiche/quiche/deps/boringssl \
        --with-quiche=/usr/src/nginx-${NGINX_VERSION}/quiche \
        --with-pcre=/usr/src/nginx-${NGINX_VERSION}/pcre-${PCRE_VERSION} \
        --with-pcre-jit \
        --with-libatomic=/usr/src/nginx-${NGINX_VERSION}/libatomic_ops-${LIBATOMIC_VERSION} \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/ngx_brotli \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/nginx-sticky-module-ng \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/headers-more-nginx-module-${MODULE_HEADERS_MORE_VERSION} \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/nginx-http-flv-module \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/ngx-fancyindex-${MODULE_FANCYINDEX_VERSION} \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/ngx_http_substitutions_filter_module \
        --add-module=/usr/src/nginx-${NGINX_VERSION}/ngx_http_geoip2_module-${MODULE_GEOIP2_VERSION} \
        --with-http_v2_hpack_enc \
        --with-http_v3_module \
    && make -j $(nproc) \
    && make install \
    \
    && rm -rf /etc/nginx/html/ \
    && mkdir -p /usr/share/nginx/html/ \
    && install -m644 html/index.html /usr/share/nginx/html/ \
    && install -m644 html/50x.html /usr/share/nginx/html/ \
    \
    && mkdir /etc/nginx/conf.d/ \
    \
    && rm -rf /usr/src/ \
    && strip /usr/sbin/nginx \
    && nginx -V

COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx.vhost.default.conf /etc/nginx/conf.d/default.conf
COPY config/logrotate /etc/nginx/logrotate

######

FROM debian:bullseye-slim

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx/ /etc/nginx/
COPY --from=builder /usr/share/nginx/ /usr/share/nginx/

RUN set -eux \
    && apt-get update -qyy \
    && apt-get install -qyy --no-install-recommends --no-install-suggests \
        cron \
        logrotate \
        libjemalloc2 \
        libxslt1.1 \
        libgd3 \
        libgeoip1 \
        libmaxminddb0 \
    && rm -rf /var/lib/apt/lists/* /var/log/* \
    \
    && echo "1 0 * * * /usr/sbin/logrotate -f /etc/logrotate.conf" > /var/spool/cron/crontabs/root \
    && addgroup --system nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --shell /bin/false nginx \
    && mkdir -p /usr/lib/nginx/modules/ \
    && ln -s /usr/lib/nginx/modules/ /etc/nginx/modules \
    \
    && mkdir /var/cache/nginx/ \
    \
    && mkdir /var/log/nginx/ \
    && ln -s /dev/stdout /var/log/nginx/access.log \
    && ln -s /dev/stderr /var/log/nginx/error.log \
    \
    && mv /etc/nginx/logrotate /etc/logrotate.d/nginx \
    && chmod 644 /etc/logrotate.d/nginx

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 443/udp

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
