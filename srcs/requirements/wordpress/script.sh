#!/bin/sh
set -e

# NE PAS TOUCHER : secret lu depuis Docker secrets
MYSQL_PASSWORD="$(cat /run/secrets/db_user_psd)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_psd)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_psd)"

# (optionnel mais utile) éviter boucle infinie

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
fi

# Créer le 2e user WordPress (exigé par le sujet)
# Attendu: WP_USER, WP_USER_EMAIL, WP_USER_PASSWORD dans l'env
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

exec php-fpm81 -F
