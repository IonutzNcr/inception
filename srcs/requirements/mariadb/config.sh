#!/bin/sh
set -e

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
SOCK="$RUNDIR/mysqld.sock"
PASSWORD="$(cat /run/secrets/db_psd)"
USER_PASSWORD="$(cat /run/secrets/db_user_psd)"

mkdir -p "$DATADIR" "$RUNDIR"
chown -R mysql:mysql "$DATADIR" "$RUNDIR"

# init si nécessaire
if [ ! -d "$DATADIR/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir="$DATADIR"
fi

# démarrer le serveur en background pour init
mariadbd --user=mysql --datadir="$DATADIR" --socket="$SOCK" &
pid="$!"

# attendre que le serveur réponde
for i in 1 2 3 4 5 6 7 8 9 10; do
  mariadb-admin --socket="$SOCK" ping >/dev/null 2>&1 && break
  sleep 1
done

# si toujours pas prêt, on échoue avec logs
mariadb-admin --socket="$SOCK" ping >/dev/null 2>&1 || {
  echo "MariaDB did not start"
  exit 1
}

# Create and check users and database
mariadb --socket="$SOCK" -e "CREATE DATABASE IF NOT EXISTS $MARIA_DATABASE ;"
mariadb --socket="$SOCK" -e "SHOW DATABASES;"
mariadb --socket="$SOCK" -e "CREATE USER IF NOT EXISTS '$ADMIN_NAME'@'%' IDENTIFIED BY '$PASSWORD';"
mariadb --socket="$SOCK" -e "GRANT ALL PRIVILEGES ON $MARIA_DATABASE.* TO '$ADMIN_NAME'@'%' ;"
mariadb --socket="$SOCK" -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$USER_PASSWORD';"
mariadb --socket="$SOCK" -e "GRANT ALL PRIVILEGES ON $MARIA_DATABASE.* TO '$MYSQL_USER'@'%' ;"

mariadb --socket="$SOCK" -e "SELECT User, Host FROM mysql.user;"


# arrêter le serveur background
mariadb-admin --socket="$SOCK" shutdown
wait "$pid" 2>/dev/null || true


# relancer en foreground (PID 1)
exec mariadbd --user=mysql --datadir="$DATADIR" \
  --port=3306 --bind-address=0.0.0.0 \
  --ssl=OFF






