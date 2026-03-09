FROM alpine:3.22

RUN apk add --no-cache nginx openssl \
 && addgroup -S www-data 2>/dev/null || true \
 && adduser  -S -D -H -s /sbin/nologin -G www-data www-data 2>/dev/null || true \
 && mkdir -p /run/nginx /var/www /var/lib/nginx \
 && chown -R www-data:www-data /run/nginx /var/www /var/lib/nginx \
 && openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 365 \
	-subj "/C=RO/ST=France/L=Paris/O=42/OU=Inception/CN=inicoara.42.fr" \
	-keyout /etc/nginx/inicoara.42.fr-key.pem \
	-out /etc/nginx/inicoara.42.fr.pem

COPY ./nginx.conf /etc/nginx/nginx.conf

ENTRYPOINT ["nginx", "-g", "daemon off;"]
