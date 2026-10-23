#!/usr/bin/env bash
# Restores a backup into a FRESH database (dropped and re-created every run),
# leaving the source database untouched.
#
# Usage: ./scripts/restore.sh [backup_file] [target_db]
#   backup_file  default: newest backups/*.dump
#   target_db    default: <DB_NAME>_restore   (e.g. hotel_restore)
#
# Restoring over the source database itself is refused unless
# ALLOW_OVERWRITE_SOURCE=yes is set.
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

backup_file="${1:-}"
target_db="${2:-${DB_NAME}_restore}"

if [[ -z "${backup_file}" ]]; then
  # Names are <db>_<YYYYmmdd_HHMMSS>.dump, so the last one in sort order is the newest.
  backup_file="$(find "${BACKUP_DIR}" -maxdepth 1 -type f -name '*.dump' 2>/dev/null | sort | tail -n 1)"
  [[ -n "${backup_file}" ]] || die "no backups found in ${BACKUP_DIR}. Run ./scripts/backup.sh first."
fi
[[ -f "${backup_file}" ]] || die "backup file not found: ${backup_file}"

[[ "${target_db}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] \
  || die "invalid target database name: ${target_db}"

if [[ "${target_db}" == "${DB_NAME}" && "${ALLOW_OVERWRITE_SOURCE:-no}" != "yes" ]]; then
  die "refusing to overwrite the source database '${DB_NAME}'. Set ALLOW_OVERWRITE_SOURCE=yes to force."
fi

require_docker
wait_for_db

# Check the file wasn't corrupted or changed since it was created.
if [[ -f "${backup_file}.sha256" ]]; then
  expected="$(cat "${backup_file}.sha256")"
  actual="$(sha256_of "${backup_file}")"
  [[ "${expected}" == "${actual}" ]] || die "checksum mismatch for ${backup_file}"
  log "Checksum OK"
else
  log "WARNING: no .sha256 file next to the backup; skipping checksum check"
fi

log "Restoring ${backup_file#"${ROOT_DIR}/"} into fresh database '${target_db}'..."

# Fresh database every time: drop (disconnecting any sessions) and re-create.
psql_db postgres -c "DROP DATABASE IF EXISTS \"${target_db}\" WITH (FORCE)"
psql_db postgres -c "CREATE DATABASE \"${target_db}\" OWNER \"${DB_USER}\""

# --single-transaction + --exit-on-error: the restore either fully succeeds
# or leaves an empty database, never a half-restored one.
db_exec pg_restore -U "${DB_USER}" -d "${target_db}" \
  --no-owner --no-acl --exit-on-error --single-transaction \
  < "${backup_file}"

psql_db "${target_db}" -c "ANALYZE"

bookings="$(psql_value "${target_db}" "SELECT count(*) FROM hotel_bookings")"
events="$(psql_value "${target_db}" "SELECT count(*) FROM booking_events")"

log "Restore complete"
log "  database:  ${target_db}"
log "  contents:  ${bookings} hotel_bookings, ${events} booking_events"
log "Next: ./scripts/verify-restore.sh ${target_db}   (compares it with '${DB_NAME}')"
