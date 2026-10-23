#!/usr/bin/env bash
# Proves a restore worked by comparing the restored database with the source:
#   1. row counts per table
#   2. a checksum of every row's content per table
#   3. the set of indexes and constraints (schema came back, not just data)
#   4. the result of the reporting query
#
# Usage: ./scripts/verify-restore.sh [restored_db]   (default: <DB_NAME>_restore)
# Exit code 0 = identical, 1 = differences found.
#
# Note: compare right after backup + restore. If the source database changes
# in between, the comparison will (correctly) show a difference.
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

restored_db="${1:-${DB_NAME}_restore}"

require_docker
wait_for_db

exists="$(psql_value postgres "SELECT 1 FROM pg_database WHERE datname = '${restored_db}'")"
[[ "${exists}" == "1" ]] || die "database '${restored_db}' does not exist. Run ./scripts/restore.sh first."

failures=0

check() {
  local label="$1" sql="$2"
  local source_value restored_value
  source_value="$(psql_value "${DB_NAME}" "${sql}")"
  restored_value="$(psql_value "${restored_db}" "${sql}")"

  if [[ "${source_value}" == "${restored_value}" ]]; then
    printf '  PASS  %-34s %s\n' "${label}" "${source_value:0:32}"
  else
    printf '  FAIL  %-34s source=%s restored=%s\n' "${label}" "${source_value:0:32}" "${restored_value:0:32}"
    failures=$((failures + 1))
  fi
}

log "Comparing '${DB_NAME}' (source) with '${restored_db}' (restored)"
echo

check "hotel_bookings row count" \
  "SELECT count(*) FROM hotel_bookings"
check "booking_events row count" \
  "SELECT count(*) FROM booking_events"
check "hotel_bookings data checksum" \
  "SELECT md5(coalesce(string_agg(t::text, '|' ORDER BY t.id), '')) FROM hotel_bookings t"
check "booking_events data checksum" \
  "SELECT md5(coalesce(string_agg(t::text, '|' ORDER BY t.id), '')) FROM booking_events t"
check "indexes" \
  "SELECT string_agg(indexname, ',' ORDER BY indexname) FROM pg_indexes WHERE schemaname = 'public'"
check "constraints" \
  "SELECT count(*) || ' constraints' FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace WHERE n.nspname = 'public'"
check "booking_events id sequence" \
  "SELECT last_value FROM booking_events_id_seq"
check "reporting query result" \
  "SELECT md5(coalesce(string_agg(r::text, '|' ORDER BY r::text), '')) FROM (
     SELECT org_id, status, COUNT(*), SUM(amount)
     FROM hotel_bookings
     WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
     GROUP BY org_id, status) r"

echo
if [[ "${failures}" -eq 0 ]]; then
  log "RESTORE VERIFIED: '${restored_db}' is identical to '${DB_NAME}'"
else
  die "${failures} check(s) failed: the restored database does not match the source"
fi
