-- =========================================================================================
-- Retail E-Commerce Analytics - 20+ Advanced SQL Business Queries
-- Author: Ravikant Yadav
-- Database Platform: SQL Server (T-SQL) / PostgreSQL Compatible
-- Description: This script contains 22 production-grade, highly optimized SQL queries
--              designed to answer critical e-commerce executive business questions regarding
--              discount sensitivities, cart conversions, acquisition channels, and LTV.
-- =========================================================================================

-- -----------------------------------------------------------------------------------------
-- QUERY 1: Executive KPI Dashboard Scorecard
-- Purpose: Calculates high-level North Star metrics: Gross revenue, total transactions,
--          average order value (AOV), total refunds, and net sales.
-- -----------------------------------------------------------------------------------------
SELECT
    COUNT(DISTINCT OrderID) AS Total_Unique_Orders,
    SUM(Quantity * ItemPrice) AS Gross_Revenue,
    ROUND(SUM(Quantity * ItemPrice) / COUNT(DISTINCT OrderID), 2) AS Average_Order_Value,
    ROUND(SUM(CASE WHEN Quantity < 0 THEN ABS(Quantity * ItemPrice) ELSE 0 END), 2) AS Total_Refunded_Amount,
    ROUND(SUM(Quantity * ItemPrice) - SUM(CASE WHEN Quantity < 0 THEN ABS(Quantity * ItemPrice) ELSE 0 END), 2) AS Net_Sales_Revenue,
    SUM(Quantity) AS Total_Units_Sold
FROM Fact_Orders;


-- -----------------------------------------------------------------------------------------
-- QUERY 2: MoM E-Commerce Revenue Growth & Seasonality Trends
-- Purpose: Evaluates Month-over-Month (MoM) order volume and gross revenue growth trends.
-- -----------------------------------------------------------------------------------------
WITH MonthlySales AS (
    SELECT
        DATETRUNC(month, OrderDate) AS Sale_Month,
        SUM(Quantity * ItemPrice) AS Monthly_Revenue,
        COUNT(DISTINCT OrderID) AS Monthly_Orders
    FROM Fact_Orders
    WHERE Quantity > 0
    GROUP BY DATETRUNC(month, OrderDate)
)
SELECT
    Sale_Month,
    Monthly_Orders,
    ROUND(Monthly_Revenue, 2) AS Monthly_Revenue,
    ROUND(Monthly_Revenue - LAG(Monthly_Revenue, 1) OVER (ORDER BY Sale_Month), 2) AS MoM_Variance,
    ROUND(((Monthly_Revenue - LAG(Monthly_Revenue, 1) OVER (ORDER BY Sale_Month)) /
           LAG(Monthly_Revenue, 1) OVER (ORDER BY Sale_Month)) * 100, 2) AS MoM_Growth_Percent
FROM MonthlySales
ORDER BY Sale_Month;


-- -----------------------------------------------------------------------------------------
-- QUERY 3: E-Commerce Funnel and Cart Conversion Rates
-- Purpose: Evaluates funnel progression rates from product views to checkout completions
--          to pinpoint where cart abandonment occurs.
-- -----------------------------------------------------------------------------------------
SELECT
    COUNT(CASE WHEN EventType = 'Product_View' THEN SessionID END) AS Total_Product_Views,
    COUNT(CASE WHEN EventType = 'Add_To_Cart' THEN SessionID END) AS Total_Adds_To_Cart,
    COUNT(CASE WHEN EventType = 'Checkout_Initiated' THEN SessionID END) AS Total_Checkouts_Initiated,
    COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) AS Total_Purchases_Completed,
    ROUND((COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) * 100.0) /
          NULLIF(COUNT(CASE WHEN EventType = 'Product_View' THEN SessionID END), 0), 2) AS Session_To_Purchase_Conversion_Percent,
    ROUND((COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) * 100.0) /
          NULLIF(COUNT(CASE WHEN EventType = 'Add_To_Cart' THEN SessionID END), 0), 2) AS Cart_Abandonment_Recovery_Percent
FROM Fact_Web_Sessions;


-- -----------------------------------------------------------------------------------------
-- QUERY 4: E-Commerce Acquisition Channel ROI & LTV Insights
-- Purpose: Evaluates performance across acquisition channels, comparing order frequency,
--          average order values, and cumulative customer lifetime value.
-- -----------------------------------------------------------------------------------------
SELECT
    AcquisitionChannel,
    COUNT(DISTINCT CustomerID) AS New_Customers_Acquired,
    COUNT(OrderID) AS Cumulative_Transactions,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Channel_Gross_Revenue,
    ROUND(SUM(Quantity * ItemPrice) / COUNT(DISTINCT CustomerID), 2) AS Customer_LTV_By_Channel
FROM Fact_Orders fo
JOIN Dim_Customer dc ON fo.CustomerID = dc.CustomerID
WHERE Quantity > 0
GROUP BY AcquisitionChannel
ORDER BY Channel_Gross_Revenue DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 5: Device-Type Performance and Purchase Preference
-- Purpose: Compares traffic shares, transactions, and revenues across mobile, tablet, and
--          desktop user groups to optimize checkout experiences.
-- -----------------------------------------------------------------------------------------
SELECT
    DeviceType,
    COUNT(DISTINCT SessionID) AS Session_Count,
    COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) AS Total_Purchases,
    ROUND((COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) * 100.0) / COUNT(DISTINCT SessionID), 2) AS Device_Conversion_Rate,
    ROUND(SUM(TransactionAmount), 2) AS Device_Generated_Revenue
FROM Fact_Web_Sessions fws
LEFT JOIN Fact_Orders fo ON fws.OrderID = fo.OrderID
GROUP BY DeviceType
ORDER BY Device_Generated_Revenue DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 6: Customer Promotion & Coupon Code Sensitivities
-- Purpose: Evaluates order conversions and profit margins for orders using discount codes
--          vs. full-price transactions to prevent margin erosion.
-- -----------------------------------------------------------------------------------------
SELECT
    CASE WHEN CouponCode IS NULL THEN 'Full Price Transaction' ELSE CONCAT('Discount: ', CouponCode) END AS Promo_State,
    COUNT(OrderID) AS Transaction_Count,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Gross_Sales,
    ROUND(AVG(DiscountAmountPercent) * 100.0, 2) AS Average_Discount_Applied_Percent,
    ROUND(SUM(Quantity * ItemPrice * GrossMarginPercent), 2) AS Realized_Profit_Margin
FROM Fact_Orders
WHERE Quantity > 0
GROUP BY CASE WHEN CouponCode IS NULL THEN 'Full Price Transaction' ELSE CONCAT('Discount: ', CouponCode) END
ORDER BY Gross_Sales DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 7: Regional Revenue Distribution & Market Share
-- Purpose: Summarizes gross transactions, sales, and localized profit margins across states
--          and countries to target logistics expansion.
-- -----------------------------------------------------------------------------------------
SELECT
    State,
    Country,
    COUNT(DISTINCT OrderID) AS Total_Orders,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Total_Revenue,
    ROUND(SUM(Quantity * ItemPrice * GrossMarginPercent), 2) AS Total_Gross_Profit,
    ROUND((SUM(Quantity * ItemPrice * GrossMarginPercent) * 100.0) / SUM(Quantity * ItemPrice), 2) AS Realized_Margin_Percent
FROM Fact_Orders fo
JOIN Dim_Geography dg ON fo.GeographyID = dg.GeographyID
WHERE Quantity > 0
GROUP BY State, Country
ORDER BY Total_Revenue DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 8: E-Commerce Product Category Affinity Matrix
-- Purpose: Evaluates top-performing categories based on gross sales, items ordered, and
--          profitability.
-- -----------------------------------------------------------------------------------------
SELECT
    ProductCategory,
    SUM(Quantity) AS Total_Units_Sold,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Category_Revenue,
    ROUND(SUM(Quantity * ItemPrice * GrossMarginPercent), 2) AS Category_Gross_Profit,
    ROUND((SUM(Quantity * ItemPrice * GrossMarginPercent) * 100.0) / SUM(Quantity * ItemPrice), 2) AS Realized_Margin_Percent
FROM Fact_Orders fo
JOIN Dim_Products dp ON fo.ProductID = dp.ProductID
WHERE Quantity > 0
GROUP BY ProductCategory
ORDER BY Category_Gross_Profit DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 9: E-Commerce Retention Cliffs (Monthly Retention Grid)
-- Purpose: Evaluates customer repeat purchase rates month-over-month to locate product
--          satisfaction issues.
-- -----------------------------------------------------------------------------------------
WITH Acquisitions AS (
    SELECT
        CustomerID,
        DATETRUNC(month, MIN(OrderDate)) AS Cohort_Month
    FROM Fact_Orders
    WHERE Quantity > 0
    GROUP BY CustomerID
),
Lapses AS (
    SELECT
        fo.CustomerID,
        a.Cohort_Month,
        DATETRUNC(month, fo.OrderDate) AS Active_Month,
        DATEDIFF(month, a.Cohort_Month, DATETRUNC(month, fo.OrderDate)) AS Month_Index
    FROM Fact_Orders fo
    JOIN Acquisitions a ON fo.CustomerID = a.CustomerID
    WHERE fo.Quantity > 0
)
SELECT
    Cohort_Month,
    Month_Index,
    COUNT(DISTINCT CustomerID) AS Active_Customers
FROM Lapses
WHERE Month_Index BETWEEN 0 AND 12
GROUP BY Cohort_Month, Month_Index
ORDER BY Cohort_Month, Month_Index;


-- -----------------------------------------------------------------------------------------
-- QUERY 10: Slipping High-Value E-Commerce Customers
-- Purpose: Highlights e-commerce customer accounts that have spent over $500 historically
--          but show no order history in 90 days.
-- -----------------------------------------------------------------------------------------
SELECT
    CustomerID,
    DATEDIFF(day, MAX(OrderDate), '2026-01-01') AS Days_Since_Last_Order,
    COUNT(DISTINCT OrderID) AS Lifetime_Orders,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Lifetime_Revenue
FROM Fact_Orders
WHERE Quantity > 0
GROUP BY CustomerID
HAVING DATEDIFF(day, MAX(OrderDate), '2026-01-01') > 90
   AND SUM(Quantity * ItemPrice) > 500.00
ORDER BY Lifetime_Revenue DESC, Days_Since_Last_Order ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 11: Daily Traffic & Sales Run Rates (Rolling Moving Averages)
-- Purpose: Calculates rolling 7-day average sales revenues to smooth out day-of-week
--          variance and highlight true underlying run-rates.
-- -----------------------------------------------------------------------------------------
WITH DailySales AS (
    SELECT
        DATETRUNC(day, OrderDate) AS Sale_Day,
        SUM(Quantity * ItemPrice) AS Daily_Revenue
    FROM Fact_Orders
    WHERE Quantity > 0
    GROUP BY DATETRUNC(day, OrderDate)
)
SELECT
    Sale_Day,
    ROUND(Daily_Revenue, 2) AS Daily_Revenue,
    ROUND(AVG(Daily_Revenue) OVER (
        ORDER BY Sale_Day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling_7Day_Average_Revenue
FROM DailySales
ORDER BY Sale_Day;


-- -----------------------------------------------------------------------------------------
-- QUERY 12: High-Value Revenue Outliers (Statistical Z-Score Filter)
-- Purpose: Highlights orders with spending profiles exceeding 3 standard deviations from
--          mean values to isolate extreme customer behaviors.
-- -----------------------------------------------------------------------------------------
WITH SalesMetrics AS (
    SELECT
        AVG(Quantity * ItemPrice) AS Avg_Spend,
        STDEV(Quantity * ItemPrice) AS Stdev_Spend
    FROM Fact_Orders
    WHERE Quantity > 0
)
SELECT
    fo.OrderID,
    fo.CustomerID,
    fo.OrderDate,
    ROUND(fo.Quantity * fo.ItemPrice, 2) AS Gross_Order_Value,
    ROUND((fo.Quantity * fo.ItemPrice - sm.Avg_Spend) / sm.Stdev_Spend, 2) AS Spend_Z_Score
FROM Fact_Orders fo
CROSS JOIN SalesMetrics sm
WHERE fo.Quantity > 0
  AND (fo.Quantity * fo.ItemPrice - sm.Avg_Spend) / sm.Stdev_Spend > 3.0
ORDER BY Gross_Order_Value DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 13: Transactional Duplication Audit
-- Purpose: Quality control audit. Flags potential identical duplicate transaction logs
--          recorded within the same minute.
-- -----------------------------------------------------------------------------------------
SELECT
    CustomerID,
    OrderID,
    OrderDate,
    Quantity,
    ItemPrice,
    COUNT(*) AS Duplicate_Occurrence_Count
FROM Fact_Orders
GROUP BY CustomerID, OrderID, OrderDate, Quantity, ItemPrice
HAVING COUNT(*) > 1
ORDER BY Duplicate_Occurrence_Count DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 14: Cart Abandonment Cost Modeling (Revenue Leakage)
-- Purpose: Estimates the total value of uncompleted transactions left in abandoned carts,
--          representing direct potential revenue recovery opportunity.
-- -----------------------------------------------------------------------------------------
SELECT
    DeviceType,
    COUNT(CASE WHEN EventType = 'Add_To_Cart' THEN SessionID END) AS Total_Adds,
    COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) AS Total_Purchases,
    COUNT(CASE WHEN EventType = 'Add_To_Cart' THEN SessionID END) -
    COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) AS Abandoned_Sessions,
    ROUND(AVG(TransactionAmount), 2) AS Average_AOV,
    ROUND((COUNT(CASE WHEN EventType = 'Add_To_Cart' THEN SessionID END) -
           COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END)) * AVG(TransactionAmount), 2) AS Estimated_Cart_Revenue_Leakage
FROM Fact_Web_Sessions fws
LEFT JOIN Fact_Orders fo ON fws.OrderID = fo.OrderID
GROUP BY DeviceType
ORDER BY Estimated_Cart_Revenue_Leakage DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 15: Repeat Purchase Velocity Matrix
-- Purpose: Measures the speed of repeat purchasing. Highlights how many days elapsed
--          between first and second purchases per customer.
-- -----------------------------------------------------------------------------------------
WITH CustomerPurchaseSequence AS (
    SELECT
        CustomerID,
        OrderDate,
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate) AS Purchase_Seq
    FROM Fact_Orders
    WHERE Quantity > 0
),
FirstTwoPurchases AS (
    SELECT
        CustomerID,
        MAX(CASE WHEN Purchase_Seq = 1 THEN OrderDate END) AS First_Order,
        MAX(CASE WHEN Purchase_Seq = 2 THEN OrderDate END) AS Second_Order
    FROM CustomerPurchaseSequence
    WHERE Purchase_Seq IN (1, 2)
    GROUP BY CustomerID
)
SELECT
    COUNT(CustomerID) AS Total_Customer_Sample,
    SUM(CASE WHEN Second_Order IS NOT NULL THEN 1 ELSE 0 END) AS Repeat_Buyers,
    ROUND((SUM(CASE WHEN Second_Order IS NOT NULL THEN 1 ELSE 0 END) * 100.0) / COUNT(CustomerID), 2) AS Repeat_Buyer_Ratio_Percent,
    AVG(DATEDIFF(day, First_Order, Second_Order)) AS Avg_Days_Between_First_And_Second_Order
FROM FirstTwoPurchases;


-- -----------------------------------------------------------------------------------------
-- QUERY 16: E-Commerce Refund Rate Audit by Category
-- Purpose: Pinpoints product categories driving high refunds to alert inventory and
--          quality control teams of operational margin losses.
-- -----------------------------------------------------------------------------------------
SELECT
    dp.ProductCategory,
    COUNT(CASE WHEN fo.Quantity > 0 THEN fo.OrderID END) AS Valid_Purchases,
    COUNT(CASE WHEN fo.Quantity < 0 THEN fo.OrderID END) AS Return_Claims,
    ROUND(SUM(CASE WHEN fo.Quantity < 0 THEN ABS(fo.Quantity * fo.ItemPrice) ELSE 0 END), 2) AS Total_Refunded_Value,
    ROUND((COUNT(CASE WHEN fo.Quantity < 0 THEN fo.OrderID END) * 100.0) /
          NULLIF(COUNT(CASE WHEN fo.Quantity > 0 THEN fo.OrderID END), 0), 2) AS Return_Rate_Percent
FROM Fact_Orders fo
JOIN Dim_Products dp ON fo.ProductID = dp.ProductID
GROUP BY dp.ProductCategory
ORDER BY Return_Rate_Percent DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 17: Customer Lifetime Value (LTV) Decile Analysis
-- Purpose: Groups customers into deciles based on lifetime spending, identifying if
--          the top 10% (Decile 1) account for the vast majority of e-commerce revenue.
-- -----------------------------------------------------------------------------------------
WITH CustomerLTV AS (
    SELECT
        CustomerID,
        SUM(Quantity * ItemPrice) AS Total_Lifetime_Spend,
        NTILE(10) OVER (ORDER BY SUM(Quantity * ItemPrice) DESC) AS Spend_Decile
    FROM Fact_Orders
    WHERE Quantity > 0
    GROUP BY CustomerID
)
SELECT
    Spend_Decile,
    COUNT(CustomerID) AS Customer_Count,
    ROUND(SUM(Total_Lifetime_Spend), 2) AS Decile_Combined_Spend,
    ROUND((SUM(Total_Lifetime_Spend) * 100.0) / (SELECT SUM(Quantity * ItemPrice) FROM Fact_Orders WHERE Quantity > 0), 2) AS Decile_Revenue_Share_Percent,
    ROUND(AVG(Total_Lifetime_Spend), 2) AS Average_Customer_Value_In_Decile
FROM CustomerLTV
GROUP BY Spend_Decile
ORDER BY Spend_Decile ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 18: Peak Traffic Hour Audits for Web Conversions
-- Purpose: Identifies the exact hours of the day with the highest traffic volume and
--          checkout conversions to optimize promotion pacing.
-- -----------------------------------------------------------------------------------------
SELECT
    DATEPART(hour, EventTimestamp) AS Hour_Of_Day,
    COUNT(DISTINCT SessionID) AS Session_Count,
    COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) AS Purchase_Completed_Volume,
    ROUND((COUNT(CASE WHEN EventType = 'Purchase_Completed' THEN SessionID END) * 100.0) / COUNT(DISTINCT SessionID), 2) AS Conversion_Rate_Percent
FROM Fact_Web_Sessions
GROUP BY DATEPART(hour, EventTimestamp)
ORDER BY Conversion_Rate_Percent DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 19: Product Affinity Bundle (Market Basket Analysis)
-- Purpose: Uses a self-join on orders to discover which product categories are most
--          commonly co-purchased in the same shopping cart.
-- -----------------------------------------------------------------------------------------
WITH OrderDetails AS (
    SELECT DISTINCT
        fo.OrderID,
        dp.ProductCategory
    FROM Fact_Orders fo
    JOIN Dim_Products dp ON fo.ProductID = dp.ProductID
    WHERE fo.Quantity > 0
)
SELECT
    o1.ProductCategory AS Primary_Category,
    o2.ProductCategory AS Paired_Category,
    COUNT(*) AS Co_Purchase_Volume
FROM OrderDetails o1
JOIN OrderDetails o2 ON o1.OrderID = o2.OrderID AND o1.ProductCategory < o2.ProductCategory
GROUP BY o1.ProductCategory, o2.ProductCategory
ORDER BY Co_Purchase_Volume DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 20: Average Basket Dimensions (Units Per Transaction)
-- Purpose: Tracks the average number of items per e-commerce order over time to evaluate
--          cross-selling and average transaction values.
-- -----------------------------------------------------------------------------------------
SELECT
    DATETRUNC(month, OrderDate) AS Transaction_Month,
    COUNT(DISTINCT OrderID) AS Unique_Orders,
    SUM(Quantity) AS Total_Units_Sold,
    ROUND(SUM(Quantity) * 1.0 / COUNT(DISTINCT OrderID), 2) AS Average_Units_Per_Order
FROM Fact_Orders
WHERE Quantity > 0
GROUP BY DATETRUNC(month, OrderDate)
ORDER BY Transaction_Month;


-- -----------------------------------------------------------------------------------------
-- QUERY 21: Rolling Quarterly Customer Acquisitions & Inflows
-- Purpose: Reviews net headcount growth. Measures total newly acquired active customers
--          by fiscal quarters to monitor channel expansion.
-- -----------------------------------------------------------------------------------------
SELECT
    DATETRUNC(quarter, FirstOrderDate) AS Fiscal_Quarter,
    COUNT(CustomerID) AS Newly_Acquired_Customers,
    ROUND(SUM(FirstOrderSpend), 2) AS Acquisition_First_Quarter_Spend,
    ROUND(AVG(FirstOrderSpend), 2) AS Avg_Initial_Acquisition_Spend
FROM (
    SELECT
        CustomerID,
        MIN(OrderDate) AS FirstOrderDate,
        SUM(CASE WHEN DATETRUNC(month, OrderDate) = DATETRUNC(month, MIN(OrderDate)) THEN Quantity * ItemPrice ELSE 0 END) AS FirstOrderSpend
    FROM Fact_Orders
    WHERE Quantity > 0
    GROUP BY CustomerID
) AS InitialSpend
GROUP BY DATETRUNC(quarter, FirstOrderDate)
ORDER BY Fiscal_Quarter;


-- -----------------------------------------------------------------------------------------
-- QUERY 22: Retail E-Commerce Executive Consolidated Grid
-- Purpose: Generates a complete regional summary matrix combining unique order counts,
--          revenue contributions, and regional profit margins.
-- -----------------------------------------------------------------------------------------
SELECT
    dg.Region,
    COUNT(DISTINCT fo.OrderID) AS Total_Regional_Orders,
    ROUND(SUM(fo.Quantity * fo.ItemPrice), 2) AS Total_Regional_Revenue,
    ROUND(SUM(fo.Quantity * fo.ItemPrice * fo.GrossMarginPercent), 2) AS Realized_Regional_Profit,
    ROUND((SUM(fo.Quantity * fo.ItemPrice * fo.GrossMarginPercent) * 100.0) / SUM(fo.Quantity * fo.ItemPrice), 2) AS Realized_Regional_Margin_Percent
FROM Fact_Orders fo
JOIN Dim_Geography dg ON fo.GeographyID = dg.GeographyID
WHERE fo.Quantity > 0
GROUP BY dg.Region
ORDER BY Total_Regional_Revenue DESC;
