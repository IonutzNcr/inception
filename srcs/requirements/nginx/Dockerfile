FROM alpine:3.22

RUN apk add --no-cache nginx \
 && addgroup -S www-data 2>/dev/null || true \
 && adduser  -S -D -H -s /sbin/nologin -G www-data www-data 2>/dev/null || true \
 && mkdir -p /run/nginx /var/www /var/lib/nginx \
 && chown -R www-data:www-data /run/nginx /var/www /var/lib/nginx

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./localhost-key.pem /etc/nginx/localhost-key.pem
COPY ./localhost.pem /etc/nginx/localhost.pem

ENTRYPOINT ["nginx", "-g", "daemon off;"]
