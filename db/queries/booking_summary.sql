-- Reporting query from the assessment: last 30 days of bookings in Delhi,
-- grouped by organisation and status.
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
