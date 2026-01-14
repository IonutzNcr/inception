FROM alpine:3.22

RUN apk add --no-cache mariadb mariadb-client 

COPY ./config.sh ./config.sh

COPY ./zz-network.cnf /etc/my.cnf.d/zz-network.cnf

RUN chmod +x ./config.sh

RUN mkdir -p /var/lib/mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["./config.sh"]




