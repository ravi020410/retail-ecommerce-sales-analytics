# Power BI Report Engineering & Implementation Guide
### Retail E-Commerce Sales & Customer Analytics (`retail_ecommerce_analytics.pbix`)

This technical implementation guide documents the data modeling, star-schema architecture, DAX business logic, and visual design specifications for the interactive 3-page Power BI report suite (`dashboards/powerbi/retail_ecommerce_analytics.pbix`).

---

## 1. Data Ingestion & Source Configuration

### Source Data Files (`data/processed/`)
Load the following cleaned CSV datasets via **Get Data → Text/CSV** (or connect directly to PostgreSQL 14+ via `Get Data → PostgreSQL Database` pointing to server `localhost`, database `retaildb`, schema `analytics`):

1. `orders_clean.csv` (Central Fact Table — 59,125 transaction lines)
2. `customers_clean.csv` (Customer Dimension — 12,000 customer accounts)
3. `products_clean.csv` (Product Catalog Dimension — 148 SKUs across 8 categories)
4. `regions_clean.csv` (Territory Dimension — 7 sales regions including surrogate key -1)
5. `returns_clean.csv` (Post-Purchase Returns Fact Table — 4,589 return events)
6. `marketing_spend_clean.csv` (Marketing Investment Fact Table — 1,296 monthly channel records across 36 months)
7. `calendar_clean.csv` (Date Spine Dimension — 1,096 dates spanning 2023–2025)
8. `rfm_segments.csv` (Engineered Customer Dimension Extension — RFM scores and cohort assignments)

### Power Query Data Type Transformation & Validation
Upon initial ingestion, verify and apply the following explicit data type mappings:

* **Dates:**
  * `orders_clean[order_date]` → `Date`
  * `customers_clean[signup_date]` → `Date`
  * `returns_clean[return_date]` → `Date`
  * `marketing_spend_clean[month]` → `Date`
  * `calendar_clean[date]` → `Date`
* **Currencies & Financial Numerics:**
  * `orders_clean[unit_price]`, `orders_clean[revenue]`, `orders_clean[cost]`, `orders_clean[gross_profit]` → `Decimal Number` (Format as Currency `$`)
  * `returns_clean[refund_amount]` → `Decimal Number` (Format as Currency `$`)
  * `marketing_spend_clean[spend]` → `Decimal Number` (Format as Currency `$`)
  * `products_clean[list_price]`, `products_clean[unit_cost]` → `Decimal Number` (Format as Currency `$`)
* **Percentages & Quantities:**
  * `orders_clean[discount_pct]` → `Percentage`
  * `orders_clean[quantity]` → `Whole Number`
* **Booleans & System Audit Flags:**
  * `orders_clean[is_guest_checkout]`, `orders_clean[is_valid_price]` → `True/False`
  * `calendar_clean[is_weekend]`, `calendar_clean[is_holiday_season]` → `True/False`

---

## 2. Dedicated Calendar Dimension Table (DAX)

To ensure robust time-intelligence calculations without relying on auto-date/time tables, ensure `calendar_clean` is properly configured or create an explicit DAX Date table:

```dax
Calendar = 
ADDCOLUMNS (
    CALENDAR ( DATE ( 2023, 1, 1 ), DATE ( 2025, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month", FORMAT ( [Date], "mmm yyyy" ),
    "Month Sort", FORMAT ( [Date], "yyyy-mm" ),
    "Quarter", "Q" & FORMAT ( [Date], "q yyyy" ),
    "Quarter Number", QUARTER ( [Date] ),
    "Day of Week", FORMAT ( [Date], "dddd" ),
    "Day Number", WEEKDAY ( [Date], 2 ),
    "Is Weekend", IF ( WEEKDAY ( [Date], 2 ) >= 6, TRUE (), FALSE () )
)
```

* **Configuration:** Select the table, navigate to **Table tools → Mark as date table**, and set the Date column to `[Date]`.
* **Sort Hierarchy:** Select the `Month` column, navigate to **Column tools → Sort by column**, and select `Month Sort`.

---

## 3. Data Model Relationships (Star Schema)

In **Model view**, establish the relational star-schema topology. All relationships follow strict 1-to-many cardinality with single-direction cross-filtering (dimensions filtering facts):

| From Table (Many Side / Fact) | To Table (One Side / Dimension) | Foreign Key | Primary Key | Cardinality | Cross Filter | Active |
|---|---|---|---|---|---|---|
| `orders_clean` | `customers_clean` | `customer_id` | `customer_id` | Many-to-One (`*:1`) | Single (`customers` filters `orders`) | Yes |
| `orders_clean` | `products_clean` | `product_id` | `product_id` | Many-to-One (`*:1`) | Single (`products` filters `orders`) | Yes |
| `orders_clean` | `regions_clean` | `region_id` | `region_id` | Many-to-One (`*:1`) | Single (`regions` filters `orders`) | Yes |
| `orders_clean` | `calendar_clean` | `order_date` | `date` | Many-to-One (`*:1`) | Single (`calendar` filters `orders`) | Yes |
| `returns_clean` | `orders_clean` | `order_id` | `order_id` | Many-to-One (`*:1`) | Single (`orders` filters `returns`) | Yes |
| `marketing_spend_clean` | `regions_clean` | `region_id` | `region_id` | Many-to-One (`*:1`) | Single (`regions` filters `spend`) | Yes |
| `rfm_segments` | `customers_clean` | `customer_id` | `customer_id` | One-to-One (`1:1`) | Both | Yes |

* **Best Practice:** Hide all foreign key columns in `orders_clean` (e.g., `customer_id`, `product_id`, `region_id`) from Report view to force report builders to use dimension attributes for slicing.

---

## 4. DAX Business Measure Catalog

Create a dedicated measure repository table named `_Measures` via **Home → Enter Data** and implement the following production business logic:

### Financial & Margin Measures
```dax
Total Revenue = 
CALCULATE (
    SUM ( orders_clean[revenue] ),
    orders_clean[is_valid_price] = TRUE
)

Total Cost = 
CALCULATE (
    SUM ( orders_clean[cost] ),
    orders_clean[is_valid_price] = TRUE
)

Total Gross Profit = 
CALCULATE (
    SUM ( orders_clean[gross_profit] ),
    orders_clean[is_valid_price] = TRUE
)

Gross Margin % = 
DIVIDE ( [Total Gross Profit], [Total Revenue], 0 )

Order Lines = 
CALCULATE (
    COUNTROWS ( orders_clean ),
    orders_clean[is_valid_price] = TRUE
)

Average Order Value = 
DIVIDE ( [Total Revenue], [Order Lines], 0 )

Revenue YoY Growth % = 
VAR CurrentRevenue = [Total Revenue]
VAR PriorYearRevenue = 
    CALCULATE (
        [Total Revenue],
        SAMEPERIODLASTYEAR ( calendar_clean[date] )
    )
RETURN
    DIVIDE ( CurrentRevenue - PriorYearRevenue, PriorYearRevenue, 0 )
```

### Customer Acquisition & Marketing Economics
```dax
Unique Customers = 
DISTINCTCOUNT ( orders_clean[customer_id] )

Total Marketing Spend = 
SUM ( marketing_spend_clean[spend] )

New Customer Count = 
DISTINCTCOUNT ( customers_clean[customer_id] )

Blended CAC = 
DIVIDE ( [Total Marketing Spend], [New Customer Count], 0 )

Marketing Efficiency Ratio = 
DIVIDE ( [Total Revenue], [Total Marketing Spend], 0 )

Guest Checkout Share % = 
VAR GuestRevenue = 
    CALCULATE (
        [Total Revenue],
        orders_clean[is_guest_checkout] = TRUE
    )
RETURN
    DIVIDE ( GuestRevenue, [Total Revenue], 0 )
```

### Returns & Net Financials
```dax
Total Refunds = 
SUM ( returns_clean[refund_amount] )

Return Rate % = 
VAR TotalReturns = DISTINCTCOUNT ( returns_clean[return_id] )
RETURN
    DIVIDE ( TotalReturns, [Order Lines], 0 )

Net Realized Revenue = 
[Total Revenue] - [Total Refunds]

Net Margin % = 
DIVIDE ( [Total Gross Profit] - [Total Refunds], [Total Revenue], 0 )
```

### RFM Cohorts & Retention Measures
```dax
Average Customer LTV = 
AVERAGE ( rfm_segments[monetary] )

Champions Revenue = 
CALCULATE (
    [Total Revenue],
    rfm_segments[segment] = "Champions"
)

At Risk Revenue Exposure = 
CALCULATE (
    [Total Revenue],
    rfm_segments[segment] = "At Risk (was frequent)"
)

At Risk Customer Count = 
CALCULATE (
    COUNTROWS ( rfm_segments ),
    rfm_segments[segment] = "At Risk (was frequent)"
)
```

---

## 5. Visual Suite Construction Specifications

### Page 1: Executive Sales & Revenue Overview
* **Header Band:** Project Title, Dynamic Date Slicer (2023–2025), Business Segment Dropdown.
* **Top KPI Scorecard (Multi-Row / Single KPI Cards):**
  * `[Total Revenue]` formatted as `$23.86M`
  * `[Gross Margin %]` formatted as `28.4%`
  * `[Average Order Value]` formatted as `$403.62`
  * `[Unique Customers]` formatted as `11.8K`
* **Monthly Revenue & Margin Trajectory (Line and Clustered Column Chart):**
  * X-Axis: `calendar_clean[Month]` (sorted by `Month Sort`)
  * Column Values: `[Total Revenue]`
  * Line Values: `[Gross Margin %]`
* **Category Volume vs. Profitability Breakdown (Clustered Bar Chart):**
  * Y-Axis: `products_clean[category]`
  * X-Axis: `[Total Revenue]` and `[Total Gross Profit]`
  * Tooltip: `[Gross Margin %]`
* **Territory Contribution Matrix (Map / Matrix Table):**
  * Rows: `regions_clean[region_name]`
  * Values: `[Total Revenue]`, `[Gross Margin %]`, `[Order Lines]`

### Page 2: Marketing Channel Performance & CAC
* **Header Band:** Executive Channel Performance Slicers, Marketing Spend Filter.
* **KPI Scorecard:**
  * `[Total Marketing Spend]` ($326.9K)
  * `[Blended CAC]` ($27.24)
  * `[Marketing Efficiency Ratio]` (72.99x)
* **CAC vs. Efficiency Return (Clustered Bar / Scatter Visual):**
  * Category: `customers_clean[acquisition_channel]`
  * Primary Bar: `[Blended CAC]` ($2.53 to $46.09)
  * Secondary Bar / Line: `[Revenue per Dollar Spent]` ($43.38 to $717.02)
* **Spend Allocation vs. Revenue Yield Mix (100% Stacked Bar Chart):**
  * Y-Axis: Channel
  * Values: Channel Spend Share vs. Channel Attributed Revenue Share
* **Marketing Detail Matrix (Table):**
  * Columns: Channel, New Customers, Total Spend, CAC, Attributed Revenue, Return Multiple.

### Page 3: RFM Customer Segmentation & Churn Risk
* **Header Band:** RFM Cohort Slicer, Customer Tier Selector.
* **KPI Scorecard:**
  * `[Champions Revenue]` ($12.8M)
  * `[At Risk Revenue Exposure]` ($6.16M)
  * `[At Risk Customer Count]` (2,331 customers)
* **RFM Segment Value Matrix (Treemap / Bar Chart):**
  * Category: `rfm_segments[segment]` (Champions, Loyal, At Risk, Lost, Developing)
  * Values: `[Total Revenue]` and Customer Count
* **Customer Segment Economics (Clustered Column Chart):**
  * X-Axis: `customers_clean[segment]` (Consumer, Small Business, Enterprise)
  * Values: Revenue per Customer ($926 Consumer vs. $10,266 Enterprise)
  * Secondary Value: `[Average Discount %]` (14.0% Enterprise vs. 4.9% Consumer)
* **High-Value At-Risk Retention Queue (Matrix Table):**
  * Columns: Customer ID, Segment, Recency (Days), Frequency (Orders), Lifetime Revenue, Churn Probability.
