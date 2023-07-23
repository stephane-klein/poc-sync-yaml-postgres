#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec postgres sh -c "cd /sqls/ && psql --quiet -U \$POSTGRES_USER \$POSTGRES_DB -f /sqls/seed.sql"

