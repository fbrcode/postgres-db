FROM postgres:11-alpine AS builder

ENV PGTAP_VERSION v1.1.0

RUN apk -U add alpine-sdk perl make gcc libc-dev openssl-dev clang llvm

RUN cd \
  && git clone -b ${PGTAP_VERSION} --depth 1 https://github.com/theory/pgtap \
  && cd pgtap \
  && make \
  && make install

RUN cd \
  && git clone --branch REL_11_STABLE https://github.com/pgaudit/pgaudit.git \
  && cd pgaudit \
  && make install USE_PGXS=1

RUN cd \
  && git clone --branch master https://github.com/eulerto/wal2json.git \
  && cd wal2json \
  && USE_PGXS=1 make \
  && USE_PGXS=1 make install

FROM postgres:11-alpine

RUN apk -U add build-base perl-dev \
  && cpan TAP::Parser::SourceHandler::pgTAP \
  && apk del -r build-base

COPY --from=builder /usr/local/share/postgresql/extension/pgtap* /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/share/postgresql/extension/pgaudit* /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/lib/postgresql/pgaudit* /usr/local/lib/postgresql/
COPY --from=builder /usr/local/lib/postgresql/wal2json* /usr/local/lib/postgresql/
COPY --from=builder /usr/local/lib/postgresql/bitcode/pgaudit* /usr/local/lib/postgresql/bitcode/
COPY --from=builder /usr/local/lib/postgresql/bitcode/wal2json* /usr/local/lib/postgresql/bitcode/
COPY --from=builder /usr/local/lib/postgresql/bitcode/wal2json/wal2json* /usr/local/lib/postgresql/bitcode/wal2json/

RUN cp /usr/local/share/postgresql/postgresql.conf.sample /etc/postgresql.conf \
  && echo "wal_level = logical" >> /etc/postgresql.conf \
  && echo "max_wal_senders = 10" >> /etc/postgresql.conf \
  && echo "max_replication_slots = 10" >> /etc/postgresql.conf \
  && echo "pgaudit.role = 'rds_pgaudit'" >> /etc/postgresql.conf \
  && echo "pgaudit.log = 'role'" >> /etc/postgresql.conf \
  && echo "pgaudit.log_catalog = 'off'" >> /etc/postgresql.conf \
  && echo "pgaudit.log_client = 'on'" >> /etc/postgresql.conf \
  && echo "pgaudit.log_level = 'debug5'" >> /etc/postgresql.conf \
  && echo "pgaudit.log_parameter = 'on'" >> /etc/postgresql.conf \
  && echo "pgaudit.log_relation = 'on'" >> /etc/postgresql.conf \
  && echo "pgaudit.log_statement_once = 'on'" >> /etc/postgresql.conf \
  && echo "shared_preload_libraries = 'pg_stat_statements,pgaudit,wal2json'" >> /etc/postgresql.conf \
  && echo "log_statement = 'all'" >> /etc/postgresql.conf \
  && echo "log_line_prefix = '%t:%r:%u@%d:[%p]:'" >> /etc/postgresql.conf

EXPOSE 5432

CMD ["postgres", "-c", "config_file=/etc/postgresql.conf"]
