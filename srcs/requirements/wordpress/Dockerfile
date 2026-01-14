FROM alpine:3.22

RUN apk add --no-cache \
    php \
    php-fpm \
    php-mysqli \
    php-json \
    php-openssl \
    php-curl \
    php-zlib \
    php-xml \
    php-phar \
    php-intl \
    php-dom \
    php-mbstring \
    php-zip \
    curl \
    tar \
    mariadb-client \
&& addgroup -S www-data 2>/dev/null || true \
&& adduser  -S -D -H -s /sbin/nologin -G www-data www-data 2>/dev/null || true

# wp-cli
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html

RUN curl -o wp.tar.gz https://wordpress.org/latest.tar.gz \
 && tar -xzf wp.tar.gz --strip-components=1 \
 && rm -f wp.tar.gz \
 && chown -R www-data:www-data /var/www/html

# PHP-FPM écoute sur 9000 (trouve le bon www.conf)
RUN FPM_WWW_CONF="$(ls -1 /etc/php*/php-fpm.d/www.conf 2>/dev/null | head -n 1)" \
 && [ -n "$FPM_WWW_CONF" ] \
 && sed -i 's|^;listen = 127.0.0.1:9000|listen = 9000|' "$FPM_WWW_CONF" \
 && sed -i 's|^user = nobody|user = www-data|' "$FPM_WWW_CONF" \
 && sed -i 's|^group = nobody|group = www-data|' "$FPM_WWW_CONF"

COPY script.sh /script.sh
RUN chmod +x /script.sh

EXPOSE 9000
ENTRYPOINT ["/script.sh"]
