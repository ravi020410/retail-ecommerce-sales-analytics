# Retail E-Commerce Sales & Customer Analytics — Executive Report
**Analyst:** Ravikant Yadav  
**Timeframe Analyzed:** January 2023 – December 2025 (3-Year Longitudinal Study)  
**Dataset Scope:** 59,125 validated order transactions across 12,000 customers, 148 SKUs, and 8 merchandise categories  

---

## Why I Built This Project

In multi-channel retail e-commerce, executive teams often look only at top-line revenue growth without understanding what is actually happening underneath: customer acquisition costs (CAC) inflating, discounting eating into gross margins, and high-value repeat buyers quietly churning.

I built this analytical system to evaluate the unit economics of a high-growth retail business over a 3-year expansion window (scaling from $1.02M to $15.89M in annual sales). I wanted to answer four practical, commercial questions:

1. **Has top-line growth compromised operating profitability?** As sales scaled 15x over 36 months, did promotional discounting erode blended gross margins?
2. **Where should marketing dollars actually be deployed?** Which acquisition channels generate true incremental return vs. those with diminishing marginal returns?
3. **How do B2B Enterprise and Consumer unit economics compare?** Are the deep volume discounts given to Enterprise accounts offset by their order frequency and lifetime value?
4. **Which churned customers are actually worth winning back?** How can we use RFM segmentation and predictive machine learning to prioritize retention capital where it yields the highest return?

---

## 1. Executive Performance Scorecard

| Metric | 3-Year Value | Context & Commercial Interpretation |
|---|---:|---|
| **Gross Realized Revenue** | **$23,863,648** | Scaled from $1.02M (2023) to $6.96M (2024) to $15.89M (2025) |
| **Gross Operating Profit** | **$6,778,574** | Cumulative profit across all validated transactions |
| **Blended Gross Margin** | **28.4%** | Remained stable in the 25.0%–29.5% band across all 36 months |
| **Total Order Transactions** | **59,125** | Filtered for valid pricing (excludes 187 catalog sync glitch rows) |
| **Average Order Value (AOV)** | **$403.62** | Driven by higher-priced Electronics and Enterprise bulk orders |
| **Total Customer Accounts** | **12,000** | Active registered accounts across 6 geographic sales regions |
| **Total Marketing Capital Deployed** | **$326,900** | Deployed across 5 primary customer acquisition channels |
| **Blended CAC** | **$27.24** | Average cost to acquire a registered paying customer |
| **Marketing Efficiency Ratio (MER)** | **72.99x** | $23.86M total revenue generated on $326.9K total marketing spend |
| **At-Risk Repeat Revenue Exposure** | **$6,160,000** | 2,331 loyal repeat customers who have surpassed 180+ days inactive |

---

## 2. Key Commercial Findings & Operational Diagnoses

### Finding 1: Rapid Revenue Scale Without Gross Margin Compression
A primary risk during rapid e-commerce scaling is margin dilution caused by aggressive promotional discounting. Here, the business demonstrated remarkable pricing discipline:
* **The Growth Curve:** Annual gross revenue expanded by **+582.7% YoY in 2024** and **+128.2% YoY in 2025**.
* **Margin Preservation:** Despite order volume growing from 2,500 orders in Year 1 to over 39,000 orders in Year 3, blended gross margin held within the **25.0%–29.5% corridor** throughout the entire 36 months, averaging **28.4% overall**.
* **Category Profit Concentration:**
  * **Electronics ($10.79M revenue, 45.2% share):** Acts as the primary customer acquisition and top-line revenue driver, but operates on the lowest margin (**16.11% gross margin**).
  * **Home ($4.16M revenue, 32.85% margin)** and **Fashion ($2.67M revenue, 48.03% margin):** Carry a disproportionate share of operating profitability, generating **$2.65M in gross profit (39.1% of total)** on just 28.6% of sales volume.
  * **Beauty ($1.43M revenue, 57.32% margin):** Generates the highest individual unit margin in the catalog, representing an under-marketed category with immediate promotional headroom.

### Finding 2: Marketing CAC Efficiency Spread (The 43x vs. 717x Return Divide)
Auditing acquisition spend against attributed revenue across the 5 marketing channels revealed an extreme efficiency disparity:

| Acquisition Channel | Total Marketing Spend | New Customers Acquired | Realized Channel CAC | Attributed Gross Revenue | Efficiency Return Multiple |
|---|---:|---:|---:|---:|---:|
| **Direct** | $2,382 | 942 | **$2.53** | $1,707,951 | **717.0x** |
| **Organic Search** | $2,428 | 948 | **$2.56** | $1,730,958 | **712.9x** |
| **Email Marketing** | $2,434 | 947 | **$2.57** | $1,709,692 | **702.4x** |
| **Paid Social** | $159,792 | 3,497 | **$45.69** | $6,957,000 | **43.5x** |
| **Paid Search** | $159,864 | 3,468 | **$46.09** | $6,938,067 | **43.4x** |

**What this means for budget allocation:**
* Paid Search and Paid Social consume **97.8% of the marketing budget ($319.7K)**. While they generate the raw customer volume required to scale, their CAC is **18x higher** than organic and retention-driven channels.
* Direct, Organic, and Email deliver massive ROI (700x+ return multiples), but are structurally capped in pure cold-acquisition volume.
* **My Recommendation:** Do not slash Paid Search entirely (which would collapse baseline acquisition volume), but reallocate **15% to 20% of paid ad budgets (~$50K–$65K)** into automated email lifecycle marketing, post-purchase replenishment workflows, and customer referral programs. This lowers blended CAC while maintaining top-line momentum.

### Finding 3: Segment Economics — Why Enterprise Accounts Justify Deeper Discounts
Comparing customer segments reveals distinct purchasing behaviors:
* **Enterprise Accounts (5.2% of customer base):**
  * Generate **$10,266 in revenue per customer** (11.1x higher than the Consumer baseline of $926).
  * Receive an average promotional discount of **14.0%** (vs. 4.9% for Consumers).
  * Despite lower gross margin percentage (23.9% Enterprise vs. 30.5% Consumer), Enterprise accounts deliver **$2,453 in gross profit per head** compared to just **$282 per Consumer**.
* **Small Business Accounts (15.8% of customer base):**
  * Average **$3,214 in revenue per customer** at a **27.8% gross margin**.
* **Commercial Implication:** Management should maintain tiered, segment-specific discount governance rather than enforcing a blanket corporate discount cap. Forcing Enterprise accounts into standard consumer discount limits would risk high-margin bulk volume.

### Finding 4: The $6.16M At-Risk Retention Opportunity
Using RFM segmentation (`sql/03_business_analysis_queries.sql`), I bucketed non-guest customers into behavioural loyalty tiers:
* **Champions (2,729 customers):** Drive **$12.82M in revenue (53.7% of total sales)**, averaging **$4,697.60** in historical purchases.
* **At-Risk Repeat Buyers (2,331 customers):** Previously demonstrated high purchase frequency and loyalty (**$2,642.52 average lifetime spend**), but have surpassed 180+ days since their last transaction. They represent **$6.16M in latent revenue exposure**.
* **Lost / Hibernating Buyers (3,279 customers):** Single-order purchasers with low initial spend (**$626.19 average spend**).
* **Retention Strategy:** Re-engagement campaigns often waste money on dormant single-order buyers who have low propensity to convert. Retention budgets must be strictly ring-fenced for the **2,331 At-Risk repeat cohort**, where win-back economics are over 4x more lucrative.

---

## 3. Machine Learning Churn Model & Domain Realism

In `notebooks/05_business_insights.ipynb`, I built a Random Forest classifier to predict 180-day customer churn:

* **Leakage-Free Validation:** Rather than using random k-fold cross-validation (which introduces temporal target leakage in customer transaction data), I split the dataset on a strict historical cutoff date (`feature_cutoff_date: 2025-01-05`, evaluating churn across a 180-day observation window through `2025-07-04`).
* **Model Discrimination:** Attained an **ROC-AUC of 0.5822**.
* **Top Predictive Features:**
  1. `segment_enc` (14.9% importance — Enterprise/SMB vs Consumer)
  2. `avg_discount` (14.3% importance — promotional dependency)
  3. `avg_order_value` (13.6% importance — basket size)
  4. `monetary` (12.2% importance — cumulative historical spend)
  5. `total_quantity` (11.2% importance — unit volume)

### Why 0.5822 AUC is an Honest, Realistic Finding:
In purely transactional order data (order dates, quantities, prices), predicting whether an e-commerce customer will return after 6 months is inherently noisy. Without clickstream data (website logins, cart abandonment, email open rates, app sessions), a transactional model cannot capture browsing intent. 

Reporting an AUC of 0.5822 demonstrates analytical integrity: I used a strict temporal split and refused to artificially inflate metrics through data leakage. For operational deployment, this model serves as an effective **churn-risk ranking score** to prioritize customer success outreach rather than an automated binary cutoff.

---

## 4. Strategic Recommendations for Leadership

1. **Reallocate 15%–20% of Paid Search Budget to Lifecycle Marketing:** Shift ~$50K–$65K out of low-efficiency paid search ($46.09 CAC) into automated email win-back and replenishment workflows ($2.57 CAC).
2. **Prioritize the 2,331 At-Risk Repeat Customers:** Ring-fence win-back ad budgets exclusively for high-LTV repeat buyers ($2,642 avg historical spend) rather than wasting marketing capital on single-purchase dormant users.
3. **Protect Enterprise Discount Structures:** Maintain tiered discount governance (allowing 12%–15% Enterprise discounts) to protect the $10,266 revenue per customer delivered by B2B accounts.
4. **Expand High-Margin Beauty & Fashion Offerings:** Feature high-margin categories (Beauty at 57.3% margin, Fashion at 48.0% margin) in homepage placements and email promotions to balance low-margin Electronics volume.
