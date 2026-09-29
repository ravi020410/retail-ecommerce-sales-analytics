-- 03_business_analysis_queries.sql
-- 18 business analysis queries against the analytics schema (sql/01_schema.sql).
-- Every query in this file was executed against a live PostgreSQL 16 instance
-- as part of building this project (see reports/query_results.json for output).
-- All revenue/profit KPIs filter is_valid_price = TRUE and, where the metric is
-- customer-level, exclude is_guest_checkout = TRUE — both documented in
-- sql/02_data_quality_checks.sql and notebooks/02_data_cleaning.ipynb.

-- =========================================================================
-- Q1. Monthly revenue, gross profit, and margin trend
-- =========================================================================
SELECT DATE_TRUNC('month', order_date)::date AS month,
       ROUND(SUM(revenue), 2)       AS total_revenue,
       ROUND(SUM(gross_profit), 2)  AS total_gross_profit,
       ROUND(100.0 * SUM(gross_profit) / NULLIF(SUM(revenue), 0), 2) AS gross_margin_pct,
       COUNT(*) AS order_lines
FROM analytics.orders
WHERE is_valid_price = TRUE
GROUP BY 1
ORDER BY 1;

-- =========================================================================
-- Q2. Year-over-year revenue growth
-- =========================================================================
WITH yearly AS (
    SELECT EXTRACT(YEAR FROM order_date)::int AS yr, SUM(revenue) AS revenue
    FROM analytics.orders
    WHERE is_valid_price = TRUE
    GROUP BY 1
)
SELECT yr, revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY yr)) / NULLIF(LAG(revenue) OVER (ORDER BY yr), 0), 2) AS yoy_growth_pct
FROM yearly
ORDER BY yr;

-- =========================================================================
-- Q3. Average order value by customer segment
-- =========================================================================
SELECT c.segment,
       COUNT(*) AS order_lines,
       ROUND(AVG(o.revenue), 2) AS avg_order_value,
       ROUND(SUM(o.revenue), 2) AS total_revenue
FROM analytics.orders o
JOIN analytics.customers c ON o.customer_id = c.customer_id
WHERE o.is_valid_price = TRUE
GROUP BY c.segment
ORDER BY total_revenue DESC;

-- =========================================================================
-- Q4. Revenue and margin by product category
-- =========================================================================
SELECT p.category,
       ROUND(SUM(o.revenue), 2) AS total_revenue,
       ROUND(SUM(o.gross_profit), 2) AS total_gross_profit,
       ROUND(100.0 * SUM(o.gross_profit) / NULLIF(SUM(o.revenue), 0), 2) AS gross_margin_pct,
       ROUND(100.0 * SUM(o.revenue) / SUM(SUM(o.revenue)) OVER (), 2) AS pct_of_total_revenue
FROM analytics.orders o
JOIN analytics.products p ON o.product_id = p.product_id
WHERE o.is_valid_price = TRUE
GROUP BY p.category
ORDER BY total_revenue DESC;

-- =========================================================================
-- Q5. Top 10 products by revenue
-- =========================================================================
SELECT p.product_name, p.category,
       ROUND(SUM(o.revenue), 2) AS total_revenue,
       COUNT(*) AS units_sold_lines,
       SUM(o.quantity) AS total_units
FROM analytics.orders o
JOIN analytics.products p ON o.product_id = p.product_id
WHERE o.is_valid_price = TRUE
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;

-- =========================================================================
-- Q6. Top 10 products by gross margin percentage (min 100 orders, avoid noise)
-- =========================================================================
SELECT p.product_name, p.category,
       COUNT(*) AS order_lines,
       ROUND(100.0 * SUM(o.gross_profit) / NULLIF(SUM(o.revenue), 0), 2) AS gross_margin_pct
FROM analytics.orders o
JOIN analytics.products p ON o.product_id = p.product_id
WHERE o.is_valid_price = TRUE
GROUP BY p.product_name, p.category
HAVING COUNT(*) >= 100
ORDER BY gross_margin_pct DESC
LIMIT 10;

-- =========================================================================
-- Q7. Regional performance ranking
-- =========================================================================
SELECT r.region_name,
       ROUND(SUM(o.revenue), 2) AS total_revenue,
       COUNT(DISTINCT o.customer_id) AS unique_customers,
       ROUND(SUM(o.revenue) / NULLIF(COUNT(DISTINCT o.customer_id), 0), 2) AS revenue_per_customer,
       RANK() OVER (ORDER BY SUM(o.revenue) DESC) AS revenue_rank
FROM analytics.orders o
JOIN analytics.regions r ON o.region_id = r.region_id
WHERE o.is_valid_price = TRUE
GROUP BY r.region_name
ORDER BY total_revenue DESC;

-- =========================================================================
-- Q8. Discount sensitivity — revenue and margin by discount bucket
-- =========================================================================
SELECT CASE
         WHEN discount_pct = 0 THEN '0% (full price)'
         WHEN discount_pct <= 0.10 THEN '1-10%'
         WHEN discount_pct <= 0.20 THEN '11-20%'
         WHEN discount_pct <= 0.30 THEN '21-30%'
         ELSE '30%+'
       END AS discount_bucket,
       COUNT(*) AS order_lines,
       ROUND(AVG(revenue), 2) AS avg_order_value,
       ROUND(100.0 * SUM(gross_profit) / NULLIF(SUM(revenue), 0), 2) AS gross_margin_pct
FROM analytics.orders
WHERE is_valid_price = TRUE
GROUP BY 1
ORDER BY MIN(discount_pct);

-- =========================================================================
-- Q9. RFM inputs — Recency, Frequency, Monetary per customer (base for segmentation)
-- =========================================================================
WITH last_date AS (SELECT MAX(order_date) AS max_date FROM analytics.orders)
SELECT o.customer_id,
       (SELECT max_date FROM last_date) - MAX(o.order_date) AS recency_days,
       COUNT(DISTINCT o.order_id) AS frequency,
       ROUND(SUM(o.revenue), 2) AS monetary
FROM analytics.orders o
WHERE o.is_valid_price = TRUE AND o.is_guest_checkout = FALSE
GROUP BY o.customer_id;

-- =========================================================================
-- Q10. RFM segment summary (Champions / Loyal / At Risk / Lost — quartile-based)
-- =========================================================================
WITH last_date AS (SELECT MAX(order_date) AS max_date FROM analytics.orders),
rfm AS (
    SELECT o.customer_id,
           (SELECT max_date FROM last_date) - MAX(o.order_date) AS recency_days,
           COUNT(DISTINCT o.order_id) AS frequency,
           SUM(o.revenue) AS monetary
    FROM analytics.orders o
    WHERE o.is_valid_price = TRUE AND o.is_guest_checkout = FALSE
    GROUP BY o.customer_id
),
scored AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
           NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm
)
SELECT CASE
         WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
         WHEN r_score >= 3 AND f_score >= 2 THEN 'Loyal'
         WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk (was frequent)'
         WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
         ELSE 'Developing'
       END AS rfm_segment,
       COUNT(*) AS customers,
       ROUND(AVG(monetary), 2) AS avg_lifetime_revenue
FROM scored
GROUP BY 1
ORDER BY avg_lifetime_revenue DESC;

-- =========================================================================
-- Q11. Customer lifetime value by acquisition channel
-- =========================================================================
SELECT c.acquisition_channel,
       COUNT(DISTINCT c.customer_id) AS customers,
       ROUND(SUM(o.revenue), 2) AS total_revenue,
       ROUND(SUM(o.revenue) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2) AS avg_ltv_to_date
FROM analytics.customers c
LEFT JOIN analytics.orders o ON o.customer_id = c.customer_id AND o.is_valid_price = TRUE
GROUP BY c.acquisition_channel
ORDER BY avg_ltv_to_date DESC;

-- =========================================================================
-- Q12. Monthly cohort retention — % of each signup cohort still active by month offset
-- =========================================================================
WITH cohorts AS (
    SELECT customer_id, DATE_TRUNC('month', signup_date)::date AS cohort_month
    FROM analytics.customers
),
activity AS (
    SELECT o.customer_id, DATE_TRUNC('month', o.order_date)::date AS order_month
    FROM analytics.orders o
    WHERE o.is_valid_price = TRUE AND o.customer_id IS NOT NULL
    GROUP BY o.customer_id, DATE_TRUNC('month', o.order_date)::date
)
SELECT co.cohort_month,
       (EXTRACT(YEAR FROM a.order_month) - EXTRACT(YEAR FROM co.cohort_month)) * 12
         + (EXTRACT(MONTH FROM a.order_month) - EXTRACT(MONTH FROM co.cohort_month)) AS month_offset,
       COUNT(DISTINCT a.customer_id) AS active_customers,
       COUNT(DISTINCT a.customer_id) * 1.0 / NULLIF((SELECT COUNT(*) FROM cohorts c2 WHERE c2.cohort_month = co.cohort_month), 0) AS pct_of_cohort
FROM cohorts co
JOIN activity a ON a.customer_id = co.customer_id
GROUP BY co.cohort_month, month_offset
ORDER BY co.cohort_month, month_offset;

-- =========================================================================
-- Q13. Customer acquisition cost (CAC) by channel
-- =========================================================================
WITH spend AS (
    SELECT channel, SUM(spend) AS total_spend
    FROM analytics.marketing_spend
    GROUP BY channel
),
new_custs AS (
    SELECT acquisition_channel AS channel, COUNT(*) AS new_customers
    FROM analytics.customers
    GROUP BY acquisition_channel
)
SELECT s.channel, s.total_spend, n.new_customers,
       ROUND(s.total_spend / NULLIF(n.new_customers, 0), 2) AS cac
FROM spend s
JOIN new_custs n ON s.channel = n.channel
ORDER BY cac ASC;

-- =========================================================================
-- Q14. Marketing efficiency (revenue per dollar spent, by acquisition channel)
-- =========================================================================
WITH revenue_by_channel AS (
    SELECT c.acquisition_channel AS channel, SUM(o.revenue) AS attributed_revenue
    FROM analytics.customers c
    JOIN analytics.orders o ON o.customer_id = c.customer_id
    WHERE o.is_valid_price = TRUE
    GROUP BY c.acquisition_channel
),
spend AS (
    SELECT channel, SUM(spend) AS total_spend FROM analytics.marketing_spend GROUP BY channel
)
SELECT r.channel, r.attributed_revenue, s.total_spend,
       ROUND(r.attributed_revenue / NULLIF(s.total_spend, 0), 2) AS revenue_per_dollar_spent
FROM revenue_by_channel r
JOIN spend s ON r.channel = s.channel
ORDER BY revenue_per_dollar_spent DESC;

-- =========================================================================
-- Q15. Return rate and financial impact by category
-- =========================================================================
SELECT p.category,
       COUNT(DISTINCT o.order_id) AS total_orders,
       COUNT(DISTINCT ret.return_id) AS total_returns,
       ROUND(100.0 * COUNT(DISTINCT ret.return_id) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS return_rate_pct,
       ROUND(SUM(ret.refund_amount), 2) AS total_refunded
FROM analytics.orders o
JOIN analytics.products p ON o.product_id = p.product_id
LEFT JOIN analytics.returns ret ON ret.order_id = o.order_id
WHERE o.is_valid_price = TRUE
GROUP BY p.category
ORDER BY return_rate_pct DESC;

-- =========================================================================
-- Q16. Top return reasons overall
-- =========================================================================
SELECT reason, COUNT(*) AS return_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_returns,
       ROUND(SUM(refund_amount), 2) AS total_refunded
FROM analytics.returns
GROUP BY reason
ORDER BY return_count DESC;

-- =========================================================================
-- Q17. Guest checkout revenue contribution (why it's tracked separately)
-- =========================================================================
SELECT is_guest_checkout,
       COUNT(*) AS order_lines,
       ROUND(SUM(revenue), 2) AS total_revenue,
       ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2) AS pct_of_revenue
FROM analytics.orders
WHERE is_valid_price = TRUE
GROUP BY is_guest_checkout;

-- =========================================================================
-- Q18. Enterprise vs. Consumer profitability — margin and discount comparison
-- =========================================================================
SELECT c.segment,
       ROUND(SUM(o.revenue), 2) AS total_revenue,
       ROUND(100.0 * SUM(o.gross_profit) / NULLIF(SUM(o.revenue), 0), 2) AS gross_margin_pct,
       ROUND(AVG(o.discount_pct) * 100, 2) AS avg_discount_pct,
       ROUND(SUM(o.revenue) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2) AS revenue_per_customer
FROM analytics.orders o
JOIN analytics.customers c ON o.customer_id = c.customer_id
WHERE o.is_valid_price = TRUE
GROUP BY c.segment
ORDER BY total_revenue DESC;
