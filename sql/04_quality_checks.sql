-- Duplicate check
SELECT record_id, COUNT(*)
FROM analytics.orders
GROUP BY 1
HAVING COUNT(*) > 1;

-- Date completeness check
SELECT COUNT(*) AS missing_dates
FROM analytics.orders
WHERE order_date IS NULL;
