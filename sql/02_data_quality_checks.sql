-- 02_data_quality_checks.sql
-- Detection queries for the 6 known data-quality issues in this dataset.
-- Each query here is the query that *found* the issue during EDA — run them
-- against the raw load (before scripts/clean_and_load.py) to reproduce the
-- audit; run them against analytics.orders after cleaning to confirm the fix.

-- 1. Duplicate order rows (same customer/product/date/price/qty repeated)
SELECT customer_id, product_id, order_date, unit_price, quantity, COUNT(*) AS dup_count
FROM analytics.orders
GROUP BY customer_id, product_id, order_date, unit_price, quantity, revenue, channel
HAVING COUNT(*) > 1;

-- 2. Guest checkouts (missing customer_id)
SELECT COUNT(*) AS guest_orders, ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM analytics.orders), 2) AS pct_of_orders
FROM analytics.orders
WHERE customer_id IS NULL;

-- 3. Inconsistent channel label casing/format
SELECT DISTINCT channel FROM analytics.orders ORDER BY channel;

-- 4. Zero or negative unit_price (pricing sync glitch)
SELECT order_id, order_date, unit_price, revenue
FROM analytics.orders
WHERE unit_price <= 0;

-- 5. Missing region_id
SELECT COUNT(*) AS orders_missing_region,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM analytics.orders), 2) AS pct_of_orders
FROM analytics.orders
WHERE region_id = -1;

-- 6. Refunds exceeding the original order's paid revenue (should be impossible)
SELECT r.return_id, r.order_id, r.refund_amount, o.revenue AS original_revenue,
       r.refund_amount - o.revenue AS over_refund_amount
FROM analytics.returns r
JOIN analytics.orders o ON r.order_id = o.order_id
WHERE r.refund_amount > o.revenue;

-- 7. Sanity check: gross_profit should equal revenue - cost for every valid row
SELECT order_id, revenue, cost, gross_profit, (revenue - cost) AS expected_gross_profit
FROM analytics.orders
WHERE is_valid_price = TRUE
  AND ROUND(revenue - cost, 2) <> ROUND(gross_profit, 2);
