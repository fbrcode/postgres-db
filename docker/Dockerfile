FROM --platform=linux/amd64 postgres:10.23-alpine3.16

RUN apk -U add alpine-sdk make gcc libc-dev openssl-dev clang llvm wget libical-dev qt5-qtbase-dev

RUN mkdir /tmp/pg_rrule \
 && cd /tmp/pg_rrule \
 && wget https://github.com/petropavel13/pg_rrule/archive/refs/tags/0.2.0.zip \
 && unzip 0.2.0.zip \
 && cd pg_rrule-0.2.0/src \
 && ln -s /usr/bin/qmake-qt5 /usr/bin/qmake \
 && mkdir /usr/include/postgresql \
 && ln -s /usr/local/include/postgresql/server/ /usr/include/postgresql/server \
 && qmake pg_rrule.pro \
 && make \
 && cp libpg_rrule.so.1.0.0 /usr/local/lib/postgresql/pg_rrule.so \
 && cp ../pg_rrule.control /usr/local/share/postgresql/extension/ \
 && cp ../sql/pg_rrule.sql /usr/local/share/postgresql/extension/pg_rrule--0.2.0.sql

EXPOSE 5432
CMD ["postgres"]

# CMD ["postgres", "-c", "config_file=/etc/postgresql.conf"]