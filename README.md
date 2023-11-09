# Postgres sample database

Repository containing postgres database v10 for FH.

## Environment variables

- `POSTGRES_HOST` - postgres host
- `POSTGRES_PORT` - postgres port
- `POSTGRES_USER` - postgres user
- `POSTGRES_PASSWORD` - postgres password
- `POSTGRES_DB` - default database

## Executing docker

### Build

```sh
docker-compose build --no-cache
```

### Start

```sh
docker-compose up -d
```

### Stop

Stop:

```sh
docker-compose down
```

Stop and drop database:

```sh
docker-compose down --volumes --remove-orphans
```

### Full Restart

```sh
docker-compose down --volumes --remove-orphans && docker-compose up -d
```
