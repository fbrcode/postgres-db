# Postgres sample database

Repository containing platform database files and deployments.

## Installation of pg-native

Deploying migrations to Amazon RDS with `db-migrate` fails with other than `pg-native` library. This is because SSL mode is enabled in RDS instances.

Solution is to install `pg-native` and use it with `db-migrate`, more instructions [here](https://www.npmjs.com/package/pg-native#install).

## Migrations

This project uses [db-migrate](https://github.com/db-migrate/node-db-migrate) as migration library. All new migrations need to be placed inside `./migrations`.

First you have to run `npm install` to install dependencies for `db-migrate`.

This will create new entry to `./migrations/sqls/` which you can fill in:

```sh
npm run migrate:create <migration-name>
```

Runs all pending migrations:

```sh
npm run migrate:up
```

Runs previous down migration:

```sh
npm run migrate:down
```

More info can be found from https://db-migrate.readthedocs.io/en/latest/Getting%20Started/commands/.

## Migration deployment

Migration deployments are done through database admins local environment. Deployment creator sets up following environment variables:

- `POSTGRES_USER_DEPLOY` Postgres database username
- `POSTGRES_PASSWORD_DEPLOY` Postgres database password
- `POSTGRES_DB_DEPLOY` Postgres database name
- `POSTGRES_PORT_DEPLOY` Postgres database port

These are deliberately named differently from the normal environment variables to avoid accidents. This script assumes that SSH tunnel is set to point to localhost and hence uses only port as configuration parameter.

After everything is set up, admin can deploy the migration to given target with `npm run migrate:up -- -e deploy`.

## Running tests

[pgTAP](https://pgtap.org/) is used to run tests, and all tests are inside `./tests` directory.

To run tests, just execute `npm test` in the directory.

## Environment variables

- `POSTGRES_USER` Username for the postgres database
- `POSTGRES_PASSWORD` Password for the postgres database
- `POSTGRES_DB` Database name
- `POSTGRES_HOST_PORT` Port to bind the postgres instance port in host computer

See more at: https://hub.docker.com/_/postgres

## Running

- Run `docker-compose up -d`
