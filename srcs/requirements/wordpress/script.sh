#!/bin/sh
set -e

MYSQL_PASSWORD="$(cat /run/secrets/db_user_psd)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_psd)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_psd)"


# Boucle pour attendre que MariaDB soit prêt avant de continuer
echo "Waiting for MariaDB to be ready..."
CONNECTED=0
for i in $(seq 1 30); do
  if mariadb-admin ping -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --skip-ssl --silent 2>/dev/null; then
    echo "MariaDB is ready!"
    CONNECTED=1
    break
  fi
  echo "Attempt $i: MariaDB not ready yet..."
  sleep 2
done

if [ "$CONNECTED" -eq 0 ]; then
  echo "ERROR: Could not connect to MariaDB after 30 attempts!"
  exit 1
fi

cd /var/www/html

# Si /var/www/html est un volume vide au 1er run, re-télécharger WP
if [ ! -f wp-settings.php ]; then
  wp core download --allow-root
fi


# wp-config.php
if [ ! -f wp-config.php ]; then
  wp config create \
    --dbname="$MARIA_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="$MYSQL_HOST" \
    --allow-root
else
  # Si wp-config.php existe déjà, s'assurer que les bonnes valeurs sont présentes
  wp config set DB_NAME "$MARIA_DATABASE" --type=constant --allow-root
  wp config set DB_USER "$MYSQL_USER" --type=constant --allow-root
  wp config set DB_PASSWORD "$MYSQL_PASSWORD" --type=constant --allow-root
  wp config set DB_HOST "$MYSQL_HOST" --type=constant --allow-root
fi

# installer WordPress
if ! wp core is-installed --allow-root; then
  wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root
else
  # Si WordPress est déjà installé, mettre à jour l'URL
  wp option update home "$WP_URL" --allow-root
  wp option update siteurl "$WP_URL" --allow-root
fi


# Cree author WP_USER, WP_USER_EMAIL, WP_USER_PASSWORD dans l'env
if [ -n "$WP_USER" ] && [ -n "$WP_USER_EMAIL" ] && [ -n "$WP_USER_PASSWORD" ]; then
  if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    wp user create \
      "$WP_USER" \
      "$WP_USER_EMAIL" \
      --user_pass="$WP_USER_PASSWORD" \
      --role=author \
      --allow-root
  fi
else
  echo "Warning: WP_USER / WP_USER_EMAIL / WP_USER_PASSWORD not set; second WP user will not be created."
fi

# permissions finales
chown -R www-data:www-data /var/www/html

# Trouve le binaire php-fpm 
PHP_FPM=$(which php-fpm* 2>/dev/null | head -n 1)
if [ -z "$PHP_FPM" ]; then
  PHP_FPM=$(ls /usr/sbin/php-fpm* 2>/dev/null | head -n 1)
fi

if [ -z "$PHP_FPM" ]; then
  echo "Error: php-fpm not found!"
  exit 1
fi

echo "Starting PHP-FPM: $PHP_FPM"
exec "$PHP_FPM" -F
