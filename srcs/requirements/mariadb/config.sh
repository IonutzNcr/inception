#!/bin/sh
set -e

DATADIR="/var/lib/mysql"
RUNDIR="/run/mysqld"
SOCK="$RUNDIR/mysqld.sock"
USER_PASSWORD="$(cat /run/secrets/db_user_psd)"

mkdir -p "$DATADIR" "$RUNDIR"
chown -R mysql:mysql "$DATADIR" "$RUNDIR"

if [ ! -d "$DATADIR/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mariadb-install-db --user=mysql --datadir="$DATADIR"
  FIRST_RUN=1
else
  echo "MariaDB data directory already exists"
  FIRST_RUN=0
fi

# démarrer le serveur en background pour init
mariadbd --user=mysql --datadir="$DATADIR" --socket="$SOCK" --skip-networking &
pid="$!"

# attendre que le socket existe et que le serveur soit prêt
echo "Waiting for MariaDB socket..."
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  if [ -S "$SOCK" ]; then
    echo "Socket found! Waiting for server readiness..."
    sleep 3
    # Test if server is ready
    if mariadb -h localhost --socket="$SOCK" --skip-ssl -e "SELECT 1;" >/dev/null 2>&1; then
      echo "MariaDB server is ready!"
      break
    fi
  fi
  echo "Attempt $i: waiting for server..."
  sleep 1
done

# vérifier que le socket existe
if [ ! -S "$SOCK" ]; then
  echo "MariaDB socket not created after 10 seconds"
  exit 1
fi

echo "Setting up database and users..."

mariadb -h localhost --socket="$SOCK" --skip-ssl -e "CREATE DATABASE IF NOT EXISTS $MARIA_DATABASE ;"

mariadb -h localhost --socket="$SOCK" --skip-ssl -e "DROP USER IF EXISTS '$MYSQL_USER'@'%';"
mariadb -h localhost --socket="$SOCK" --skip-ssl -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$USER_PASSWORD';"
mariadb -h localhost --socket="$SOCK" --skip-ssl -e "GRANT ALL PRIVILEGES ON $MARIA_DATABASE.* TO '$MYSQL_USER'@'%' ;"

mariadb -h localhost --socket="$SOCK" --skip-ssl -e "FLUSH PRIVILEGES;"

echo "Database setup complete!"


# arrêter le serveur background
kill "$pid"
wait "$pid" 2>/dev/null || true


# relancer en foreground (PID 1)
exec mariadbd --user=mysql --datadir="$DATADIR" \
  --port=3306 --bind-address=0.0.0.0






