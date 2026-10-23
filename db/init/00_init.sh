#!/usr/bin/env bash
# Runs once, automatically, when the Postgres container starts with an empty
# data volume (mounted into /docker-entrypoint-initdb.d).
# Applies every migration in order, then the seed data.
set -euo pipefail

run_sql() {
  echo "init: applying $1"
  psql -v ON_ERROR_STOP=1 --no-psqlrc \
       --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" \
       -v booking_count="${SEED_BOOKING_COUNT:-50000}" \
       -f "$1"
}

for migration in /db/migrations/*.sql; do
  run_sql "${migration}"
done

for seed in /db/seed/*.sql; do
  run_sql "${seed}"
done

echo "init: database ready"
