#!/usr/bin/env bash
# Shared helpers for the database scripts. Sourced, not executed.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}" || exit 1

# Load .env if present so scripts and docker-compose.yml share one config.
if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +a
fi

DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-hotel}"
DB_USER="${DB_USER:-hotel_user}"
BACKUP_DIR="${BACKUP_DIR:-${ROOT_DIR}/backups}"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
die() { printf '[%s] ERROR: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; exit 1; }

# Run a command inside the database container (no TTY, so binary dumps stay clean).
db_exec() {
  docker compose exec -T "${DB_SERVICE}" "$@"
}

# psql against a given database inside the container.
#   psql_db <database> [psql args...]
psql_db() {
  local database="$1"
  shift
  # client_min_messages=warning hides harmless NOTICEs like "does not exist, skipping".
  db_exec env PGOPTIONS="-c client_min_messages=warning" \
    psql -v ON_ERROR_STOP=1 -X -q -U "${DB_USER}" -d "${database}" "$@"
}

# Single value from a query, e.g. count=$(psql_value hotel "SELECT count(*) FROM t")
psql_value() {
  psql_db "$1" -t -A -c "$2"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'   # macOS
  fi
}

require_docker() {
  command -v docker >/dev/null 2>&1 || die "docker is not installed or not in PATH"
  docker compose version >/dev/null 2>&1 || die "docker compose (v2) is required"
  if ! docker compose ps --status running --services 2>/dev/null | grep -qx "${DB_SERVICE}"; then
    die "the '${DB_SERVICE}' container is not running. Start it with: docker compose up -d"
  fi
}

# Wait until Postgres accepts TCP connections AND the init scripts have finished.
# During first start-up the image runs init scripts on a temporary server that
# only listens on a Unix socket, so checking TCP avoids reporting "ready" while
# the seed is still loading.
wait_for_db() {
  local attempts="${DB_WAIT_ATTEMPTS:-60}"
  for ((i = 1; i <= attempts; i++)); do
    if db_exec pg_isready -q -h 127.0.0.1 -U "${DB_USER}" -d "${DB_NAME}" >/dev/null 2>&1 \
      && [[ "$(psql_value "${DB_NAME}" "SELECT to_regclass('public.booking_events') IS NOT NULL" 2>/dev/null)" == "t" ]]; then
      return 0
    fi
    sleep 2
  done
  die "database '${DB_NAME}' was not ready after $((attempts * 2))s (check: docker compose logs ${DB_SERVICE})"
}
