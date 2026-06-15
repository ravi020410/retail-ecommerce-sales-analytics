-- Monthly KPI trend
SELECT
    DATE_TRUNC('month', order_date) AS month,
    COUNT(*) AS records,
    SUM(revenue) AS total_value
FROM analytics.orders
GROUP BY 1
ORDER BY 1;

-- Quality profile
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT record_id) AS distinct_records
FROM analytics.orders;
