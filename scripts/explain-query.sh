#!/usr/bin/env bash
# Shows the reporting query plan WITHOUT and WITH the index, so the effect of
# idx_hotel_bookings_city_created_at is visible. The "without" run drops the
# index inside a transaction and rolls back, so nothing is changed.
#
# Usage: ./scripts/explain-query.sh
set -euo pipefail
# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_docker
wait_for_db

QUERY="SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status"

psql_db "${DB_NAME}" <<SQL
\echo '=============== WITHOUT index (sequential scan) ==============='
BEGIN;
DROP INDEX idx_hotel_bookings_city_created_at;
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${QUERY};
ROLLBACK;
\echo
\echo '=============== WITH index (index-only scan) =================='
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) ${QUERY};
\echo
\echo '=============== Query result =================================='
${QUERY}
ORDER BY org_id, status;
SQL
