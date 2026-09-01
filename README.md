# 🛒 TheLook eCommerce: Revenue & Retention Analytics 

**Author:** Rendi Dwi Andika  
**Tools:** Google Cloud BigQuery, SQL, Looker Studio  
**Dataset Source:** [Google Cloud Public Datasets (`bigquery-public-data.thelook_ecommerce`)](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)

## 📌 Project Overview
TheLook eCommerce is a public dataset provided by Google Cloud that simulates a large-scale online apparel retailer. 

**Business Case:**  
On paper, TheLook's Gross Merchandise Value (GMV) shows consistent month-over-month growth. However, vanity metrics often mask underlying operational inefficiencies. This project performs an end-to-end Exploratory Data Analysis (EDA) using SQL to look past the top-line revenue and objectively address three main issues: how much cash is actually secured, which products are silently draining margins, and whether customers are returning after their first purchase.

---

## 1. Financial Leakage: Gross Revenue vs. Realized Cash
**Problem:** High GMV does not necessarily mean a full bank account. How much potential revenue is lost due to canceled or returned orders?

<img width="1392" height="613" alt="GMV vs Realized Revenue" src="https://github.com/user-attachments/assets/b3808837-4f16-4ce2-a983-03bda76c4666" />

**Key Findings:** 
The top-line GMV numbers are highly misleading. TheLook consistently leaks between **24% - 27%** of its revenue every month. Even when GMV peaked at over $800k in mid-2026, the actual secured money (*realized revenue*) hovered only around 55% - 60%. The rest vanished due to failed transactions and product returns.

🔗 **SQL Script:** [`01_financial_leakage_audit.sql`](01_financial_leakage_audit.sql)

---

## 2. Product Quality: Cash Cows vs. Margin Drainers
**Problem:** Out of tens of thousands of items, which categories drive actual profit, and which are logistical burdens due to high return rates or pricing errors?

<img width="1240" height="500" alt="Pelaporan Data Studio - 01_09_26, 22 11_Untitled Page_Diagram sebar" src="https://github.com/user-attachments/assets/560d7d77-8c6d-4932-b3ae-9a5b3d3f2960" />

**Key Findings:** 
Product performance is heavily polarized. Based on the profitability matrix, the catalog falls into three main categories:
* **Tier 1 (Core):** The cash cows. They generate above ~$300 in net profit (top 20% of the catalog) with safe return rates (<10%).
* **Tier 2 (Risk):** High-profit products, but return rates worse than 90% of the catalog (≥18%). Margins are being heavily consumed by reverse logistics (return shipping).
* **Tier 3 (Loss Maker):** Identified multiple transactions with negative margins (items sold below base cost).

🔗 **SQL Script:** [`02_product_profitability_matrix.sql`](02_product_profitability_matrix.sql)

**Methodology note — how the thresholds were chosen:**
The profit and return-rate cutoffs used to define each tier are not arbitrary round numbers. They were derived by running [`00_profitability_threshold_distribution.sql`](00_profitability_threshold_distribution.sql) first, which ranks every product's profit and return rate as a percentile against the rest of the catalog (using `PERCENT_RANK()` / `APPROX_QUANTILES()`). The actual distribution came out lower than initially assumed: median (`P50`) realized gross profit across the catalog is only ~$139, and even the top 10% of products (`P90`) top out around ~$554. Based on this, the "High Profit" cutoff was set at **$300** (~`P80`, roughly the top 20% of products), and the "High Return Risk" cutoff was set at **18%** (~`P90` of return_rate_pct), meaning a product is only flagged as high-risk when its return rate is worse than nearly all its peers, not just modestly above average.

---

## 3. Customer Loyalty (M0-M6 Cohort Retention)
**Problem:** Does the customer acquisition effort translate into sustainable repeat purchases in the following months?

<img width="990" height="655" alt="cihuyyyy" src="https://github.com/user-attachments/assets/579a42ea-b497-4a76-80c4-a364d2dc7ae1" />

**Key Findings:** 
There is a severe customer loyalty crisis. By the first month following the initial purchase (M1), the retention rate free-falls to an average of **1.5%**. This reveals that **98.5%** of the platform's user base consists of *one-time buyers* who never return.

🔗 **SQL Script:** [`03_customer_cohort_retention.sql`](03_customer_cohort_retention.sql)

---

## 💡 Conclusion & Business Recommendations
TheLook's high GMV is driven purely by aggressive new-user acquisition, not operational efficiency or customer loyalty. To protect margins and build a sustainable business, management must take immediate action:

* **Audit Tier 2 Products:** Conduct strict audits on sizing charts and warehouse Quality Control (QC) before shipping to suppress the 15%+ return rate.
* **Halt "Loss Maker" Promotions:** Review the automated discount and pricing logic for Tier 3 items to ensure no orders result in negative margins.
* **Aggressively Chase Repeat Orders:** Build a dedicated retention marketing funnel. Deploy automated re-activation campaigns or special discount vouchers between Day 15 and Day 30 post-purchase to rescue the collapsing M1 retention rate.
