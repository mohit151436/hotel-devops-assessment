-- 001_create_tables.sql
-- Core booking tables. Based on the suggested schema, plus constraints that
-- keep the data consistent (valid dates, non-negative amounts, known statuses,
-- normalised city names) and a foreign key from events to bookings.

CREATE TABLE IF NOT EXISTS hotel_bookings (
    id             UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id         UUID          NOT NULL,
    hotel_id       VARCHAR(100)  NOT NULL,
    city           VARCHAR(100)  NOT NULL,
    checkin_date   DATE          NOT NULL,
    checkout_date  DATE          NOT NULL,
    amount         NUMERIC(12,2) NOT NULL,
    status         VARCHAR(50)   NOT NULL,
    created_at     TIMESTAMP     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_hotel_bookings_dates
        CHECK (checkout_date > checkin_date),
    CONSTRAINT chk_hotel_bookings_amount
        CHECK (amount >= 0),
    CONSTRAINT chk_hotel_bookings_status
        CHECK (status IN ('pending', 'confirmed', 'checked_in', 'completed', 'cancelled', 'refunded')),
    -- Cities are stored lowercase so equality filters such as city = 'delhi'
    -- always match and can use a plain B-tree index (no lower(city) needed).
    CONSTRAINT chk_hotel_bookings_city_lowercase
        CHECK (city = lower(city))
);

CREATE TABLE IF NOT EXISTS booking_events (
    id          BIGSERIAL     PRIMARY KEY,
    booking_id  UUID          NOT NULL
                              REFERENCES hotel_bookings (id) ON DELETE CASCADE,
    event_type  VARCHAR(100)  NOT NULL,
    payload     JSONB,
    created_at  TIMESTAMP     NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hotel_bookings IS 'One row per hotel booking.';
COMMENT ON TABLE booking_events IS 'Append-only lifecycle events for a booking.';
