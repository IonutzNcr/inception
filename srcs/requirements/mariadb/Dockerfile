FROM alpine:3.22

RUN apk add --no-cache mariadb mariadb-client

COPY ./config.sh ./config.sh

RUN mkdir -p /var/lib/mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

#RUN mariadb-install-db --user=mysql --datadir=/var/lib/mysql
#USER mysql

EXPOSE 3306

#CMD sh -c "whoami && mariadb-install-db --user=mysql --datadir=/var/lib/mysql && mariadbd --user=mysql --datadir=/var/lib/mysql"

ENTRYPOINT mariadb-install-db --user=mysql --datadir=/var/lib/mysql && service mysql start && mysql -uroot



