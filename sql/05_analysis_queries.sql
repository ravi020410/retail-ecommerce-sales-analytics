-- Portfolio-ready analytical query examples for Retail Analytics
-- Add table-specific joins after loading the dimension tables.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(revenue) AS value
    FROM analytics.orders
    GROUP BY 1
)
SELECT
    month,
    value,
    value - LAG(value) OVER (ORDER BY month) AS absolute_change,
    value / NULLIF(LAG(value) OVER (ORDER BY month), 0) - 1 AS growth_rate
FROM monthly
ORDER BY month;
