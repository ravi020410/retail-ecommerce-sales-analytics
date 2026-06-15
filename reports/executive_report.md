# Retail Analytics Executive Report

## Executive Summary

- **Business performance is measurable end to end.** The project combines synthetic raw source tables, cleaning logic, SQL, Python notebooks, Excel analysis, and dashboard-ready visuals.
- **The KPI model is recruiter-ready.** Metrics are defined in business terms and supported by reproducible tables under `data/cleaned`.
- **Recommended next step:** Load the cleaned CSVs into PostgreSQL and Power BI Desktop, then connect the documented DAX measures and dashboard pages.

## Key Findings With Visual Evidence

- **Revenue:** $5.4M
- **Gross Profit:** $2.0M
- **Profit Margin:** 36.8%
- **Average Order Value:** 69.7
- **Customer Acquisition Cost:** 3,538.1
- **Customer Retention Rate:** 82.2%
- **Repeat Purchase Rate:** 96.7%
- **Customer Lifetime Value:** 945.9
- **Monthly Revenue Growth:** 0.2%
- **Regional Growth Rate:** 2.4%
- **Top Products:** Fashion, Home, Office, Fitness, Grocery
- **Bottom Products:** Fitness, Grocery, Outdoor, Beauty, Electronics

The top-level movement is summarized in `visuals/01_monthly_trend.svg`. Supporting breakdowns are stored under `visuals/` and embedded in the README.

## Recommendations

1. Review the strongest and weakest segments each month, then prioritize two improvement experiments.
2. Use the SQL quality checks before refreshing dashboards.
3. Publish the dashboard screenshots and report PDFs after replacing personal portfolio links.

## Future Opportunities

- Add live database refresh through PostgreSQL.
- Add Power BI drill-through pages from the dashboard specification.
- Add model monitoring or forecasting experiments in the Python notebooks.

## Caveats and Assumptions

- Data is synthetic and designed for portfolio demonstration.
- Power BI `.pbix` creation requires Power BI Desktop and must be completed locally.
- GitHub URLs require authenticated repository creation and publishing.
