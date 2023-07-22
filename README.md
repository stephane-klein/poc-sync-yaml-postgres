# POC Sync Yaml <=> PostgreSQL

Context: https://github.com/stephane-klein/backlog/issues/264

## Getting started

```sh
$ asdf install
```

```sh
$ docker compose up -d --wait
```

```
$ ./feeds-to-db.js
$ ./scripts/pgcli.sh
postgres@127:postgres> select * from main.feeds;
+-------------+-------------+
| slug        | name        |
|-------------+-------------|
| science4all | Science4All |
| heu7reka    | Heu?reka    |
+-------------+-------------+
SELECT 2
Time: 0.005s
```

## Reminder

```sh
$ pnpm run prettier-check
```
