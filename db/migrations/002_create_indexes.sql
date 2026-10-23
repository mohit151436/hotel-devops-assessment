-- 002_create_indexes.sql
-- Indexes for the reporting query and for booking_events lookups.
-- See README.md, "Query optimisation", for the reasoning and EXPLAIN output.

-- Reporting query:
--   WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status  ->  COUNT(*), SUM(amount)
--
-- * city first:        equality filter, narrows to one city.
-- * created_at second: range filter, scanned in order within that city.
-- * INCLUDE columns:   org_id, status and amount are stored in the index leaf
--                      pages, so Postgres answers the query with an
--                      index-only scan and never touches the table.
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

-- Foreign keys are not indexed automatically in PostgreSQL. This index serves
-- "events for a booking" lookups (ordered by time) and keeps ON DELETE CASCADE
-- from scanning the whole events table.
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id_created_at
    ON booking_events (booking_id, created_at);
