-- 001_seed_data.sql
-- Generates realistic sample data:
--   * :booking_count hotel bookings (default 50,000; the assessment needs >= 100)
--   * 8 organisations, 10 cities, 6 statuses, ~40 hotels per city
--   * created_at spread over the last 365 days, so the 30-day report has data
--   * lifecycle events (created, paid, checked in, ...) for ~70% of bookings
--
-- Why 50,000 and not 100? With 100 rows the whole table fits in one page and
-- Postgres correctly prefers a sequential scan, so an index can't be shown to
-- help. 50k rows still loads in a few seconds and makes EXPLAIN meaningful.
-- Override with: SEED_BOOKING_COUNT=100 docker compose up
--
-- Run directly with: psql -v booking_count=1000 -f db/seed/001_seed_data.sql

\if :{?booking_count}
\else
  \set booking_count 50000
\endif

\echo 'seed: inserting' :booking_count 'hotel bookings'

-- Fixed seed so the distribution is the same on every run.
\o /dev/null
SELECT setseed(0.42);
\o

INSERT INTO hotel_bookings
    (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    gen_random_uuid(),
    orgs.ids[1 + floor(random() * array_length(orgs.ids, 1))::int],
    upper(left(c.city, 3)) || '-HTL-' || lpad((1 + floor(random() * 40))::text, 3, '0'),
    c.city,
    checkin,
    checkin + nights,
    round((nights * (1500 + random() * 13500))::numeric, 2),   -- INR per night
    s.status,
    created_at
FROM generate_series(1, :booking_count) AS n
CROSS JOIN (
    SELECT ARRAY[
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000001'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000002'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000003'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000004'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000005'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000006'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000007'::uuid,
        '0b1f9a3e-1c2d-4e5f-8a9b-000000000008'::uuid
    ] AS ids
) AS orgs
CROSS JOIN LATERAL (
    SELECT (ARRAY['delhi', 'mumbai', 'bengaluru', 'hyderabad', 'chennai',
                  'kolkata', 'pune', 'jaipur', 'goa', 'gurugram'])
           [1 + floor(random() * 10)::int + (n * 0)] AS city   -- n*0 forces per-row evaluation
) AS c
CROSS JOIN LATERAL (
    -- Weighted status mix: mostly confirmed/completed, some cancellations.
    SELECT CASE
             WHEN r < 0.40 THEN 'confirmed'
             WHEN r < 0.65 THEN 'completed'
             WHEN r < 0.80 THEN 'cancelled'
             WHEN r < 0.90 THEN 'pending'
             WHEN r < 0.95 THEN 'checked_in'
             ELSE 'refunded'
           END AS status
    FROM (SELECT random() + (n * 0) AS r) AS x
) AS s
CROSS JOIN LATERAL (
    SELECT date_trunc('second', NOW()::timestamp - random() * INTERVAL '365 days' + (n * 0) * INTERVAL '1 second') AS created_at
) AS t
CROSS JOIN LATERAL (
    SELECT t.created_at::date + (1 + floor(random() * 60))::int AS checkin,   -- booked 1-60 days ahead
           (1 + floor(random() * 7))::int + (n * 0)              AS nights    -- 1-7 nights
) AS d;

\echo 'seed: inserting booking events'

-- Lifecycle events that match each booking's status. About 70% of bookings get
-- events (selected deterministically by hashing the booking id).
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
    b.id,
    e.event_type,
    jsonb_build_object(
        'org_id',   b.org_id,
        'hotel_id', b.hotel_id,
        'city',     b.city,
        'status',   b.status,
        'amount',   b.amount,
        'currency', 'INR',
        'channel',  (ARRAY['web', 'mobile', 'partner_api'])[1 + abs(hashtext(b.id::text || e.event_type)) % 3]
    ) || e.extra,
    CASE e.anchor
        WHEN 'created'  THEN b.created_at + e.delay
        WHEN 'checkin'  THEN b.checkin_date + TIME '14:00' + e.delay
        WHEN 'checkout' THEN b.checkout_date + TIME '11:00' + e.delay
    END
FROM hotel_bookings AS b
JOIN (
    VALUES
        ('booking_created',   'created',  INTERVAL '0 minutes',  '{}'::jsonb,
            ARRAY['pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'refunded']),
        ('payment_captured',  'created',  INTERVAL '2 minutes',  '{"method": "card"}'::jsonb,
            ARRAY['confirmed', 'checked_in', 'completed', 'refunded']),
        ('booking_confirmed', 'created',  INTERVAL '3 minutes',  '{}'::jsonb,
            ARRAY['confirmed', 'checked_in', 'completed', 'refunded']),
        ('guest_checked_in',  'checkin',  INTERVAL '0 minutes',  '{}'::jsonb,
            ARRAY['checked_in', 'completed']),
        ('guest_checked_out', 'checkout', INTERVAL '0 minutes',  '{}'::jsonb,
            ARRAY['completed']),
        ('booking_cancelled', 'created',  INTERVAL '1 day',      '{"reason": "guest_request"}'::jsonb,
            ARRAY['cancelled', 'refunded']),
        ('refund_issued',     'created',  INTERVAL '3 days',     '{"refund_type": "full"}'::jsonb,
            ARRAY['refunded'])
) AS e (event_type, anchor, delay, extra, statuses)
    ON b.status = ANY (e.statuses)
WHERE abs(hashtext(b.id::text)) % 10 < 7
ORDER BY b.created_at, e.delay;

-- Fresh statistics for the planner, and an up-to-date visibility map so the
-- reporting query can use an index-only scan straight away.
VACUUM (ANALYZE) hotel_bookings;
VACUUM (ANALYZE) booking_events;

\echo 'seed: summary'
SELECT 'hotel_bookings' AS table_name, COUNT(*) AS rows FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events;
