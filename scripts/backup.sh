#!/usr/bin/env bash
# Creates a timestamped, compressed dump of the local database.
#
# Usage: ./scripts/backup.sh
# Output: backups/<db>_<YYYYmmdd_HHMMSS>.dump  (+ .sha256 checksum file)
#
# Env overrides: DB_NAME, DB_USER, BACKUP_DIR, BACKUP_RETENTION_DAYS (default 7)
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

require_docker
wait_for_db

mkdir -p "${BACKUP_DIR}"
timestamp="$(date '+%Y%m%d_%H%M%S')"
backup_file="${BACKUP_DIR}/${DB_NAME}_${timestamp}.dump"
partial_file="${backup_file}.partial"

# Never leave a half-written dump behind if anything fails.
trap 'rm -f "${partial_file}"' EXIT

log "Backing up database '${DB_NAME}'..."
# Custom format (-Fc): compressed, and pg_restore can restore it selectively.
# --no-owner/--no-acl make the dump portable to a database with other roles.
db_exec pg_dump -U "${DB_USER}" -d "${DB_NAME}" \
  --format=custom --compress=6 --no-owner --no-acl \
  > "${partial_file}"

[[ -s "${partial_file}" ]] || die "pg_dump produced an empty file"

# Prove the archive is readable before calling the backup good.
db_exec pg_restore --list < "${partial_file}" > /dev/null \
  || die "dump failed integrity check (pg_restore --list)"

mv "${partial_file}" "${backup_file}"
sha256_of "${backup_file}" > "${backup_file}.sha256"

bookings="$(psql_value "${DB_NAME}" "SELECT count(*) FROM hotel_bookings")"
events="$(psql_value "${DB_NAME}" "SELECT count(*) FROM booking_events")"

log "Backup complete"
log "  file:      ${backup_file#"${ROOT_DIR}/"}"
log "  size:      $(du -h "${backup_file}" | awk '{print $1}')"
log "  sha256:    $(cat "${backup_file}.sha256")"
log "  contents:  ${bookings} hotel_bookings, ${events} booking_events"

# Retention: delete local dumps older than BACKUP_RETENTION_DAYS.
deleted="$(find "${BACKUP_DIR}" -maxdepth 1 -type f \( -name '*.dump' -o -name '*.dump.sha256' \) \
  -mtime +"${BACKUP_RETENTION_DAYS}" -print -delete | wc -l | tr -d ' ')"
if [[ "${deleted}" -gt 0 ]]; then
  log "Retention: removed ${deleted} file(s) older than ${BACKUP_RETENTION_DAYS} days"
fi

log "Next: ./scripts/restore.sh   (restores the latest backup into a fresh database)"
