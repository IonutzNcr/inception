#!/bin/sh

mariadb-install-db --user=$MYSQL_USER --datadir=/var/lib/mysql

rc-service mariadb start

mariadb-secure-installation

