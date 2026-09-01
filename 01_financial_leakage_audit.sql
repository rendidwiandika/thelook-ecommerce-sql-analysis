/*
================================================================================
Phase 1: Financial Leakage & Fulfillment Health Audit
Author: Rendi Dwi Andika
================================================================================
Tujuan:
Menganalisis disparitas antara GMV (Gross Merchandise Value) dan Realized Revenue,
serta mengidentifikasi 'Revenue Leakage' akibat Cancelled & Returned orders.
================================================================================
*/

WITH transaction_base AS (
    SELECT 
        oi.id AS order_item_id,
        oi.order_id,
        oi.user_id,
        oi.product_id,
        oi.sale_price,
        p.cost AS product_cost,
        p.category AS product_category,
        p.brand AS product_brand,
        LOWER(oi.status) AS status,
        DATE(oi.created_at) AS order_date,
        FORMAT_DATE('%Y-%m', DATE(oi.created_at)) AS year_month,
        -- Perhitungan Hari Pengiriman (Fulfillment Duration)
        DATE_DIFF(DATE(oi.delivered_at), DATE(oi.shipped_at), DAY) AS shipping_days,
        DATE_DIFF(DATE(oi.shipped_at), DATE(oi.created_at), DAY) AS handling_days
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` p 
        ON oi.product_id = p.id
),

monthly_leakage_audit AS (
    SELECT 
        year_month,
        COUNT(DISTINCT order_id) AS total_gross_orders,
        ROUND(SUM(sale_price), 2) AS gross_merchandise_value,
        
        -- Transaksi Bersih (Complete & Shipped)
        ROUND(SUM(CASE WHEN status IN ('complete', 'shipped') THEN sale_price ELSE 0 END), 2) AS realized_revenue,
        ROUND(SUM(CASE WHEN status IN ('complete', 'shipped') THEN (sale_price - product_cost) ELSE 0 END), 2) AS realized_net_profit,
        
        -- Kebocoran Pendapatan (Cancelled & Returned)
        ROUND(SUM(CASE WHEN status = 'cancelled' THEN sale_price ELSE 0 END), 2) AS cancelled_loss_value,
        ROUND(SUM(CASE WHEN status = 'returned' THEN sale_price ELSE 0 END), 2) AS returned_loss_value,
        
        -- Rasio Kebocoran (Leakage Rate)
        ROUND((SUM(CASE WHEN status IN ('cancelled', 'returned') THEN sale_price ELSE 0 END) / NULLIF(SUM(sale_price), 0)) * 100, 2) AS revenue_leakage_rate_pct
    FROM transaction_base
    GROUP BY year_month
)

SELECT 
    year_month,
    gross_merchandise_value,
    realized_revenue,
    realized_net_profit,
    cancelled_loss_value,
    returned_loss_value,
    revenue_leakage_rate_pct,
    -- Margin Profit Riil terhadap Pendapatan Terealisasi
    ROUND((realized_net_profit / NULLIF(realized_revenue, 0)) * 100, 2) AS realized_profit_margin_pct
FROM monthly_leakage_audit
WHERE year_month >= '2023-01' -- Filter periode stabil
ORDER BY year_month ASC;


/*
================================================================================
Phase 2: Product Portfolio Profitability & Anomaly Detection
Author: Rendi Dwi Andika
================================================================================
Tujuan:
Mengkategorikan performa produk ke dalam Risk & Profitability Matrix:
1. High Margin - Low Return (Star)
2. Low Margin - High Return (Toxic / Margin Drainer)
3. Negative Profit Anomaly (Penyimpangan Harga / Rugi)
================================================================================
*/

WITH product_metrics AS (
    SELECT 
        p.category AS product_category,
        p.brand AS product_brand,
        p.name AS product_name,
        COUNT(oi.id) AS total_units_ordered,
        
        -- Tingkat Retur per Produk
        COUNT(CASE WHEN LOWER(oi.status) = 'returned' THEN 1 END) AS return_count,
        ROUND(COUNT(CASE WHEN LOWER(oi.status) = 'returned' THEN 1 END) / NULLIF(COUNT(oi.id), 0) * 100, 2) AS return_rate_pct,
        
        -- Metrik Finansial
        ROUND(AVG(oi.sale_price), 2) AS avg_sale_price,
        ROUND(AVG(p.cost), 2) AS avg_cost,
        ROUND(SUM(CASE WHEN LOWER(oi.status) = 'complete' THEN (oi.sale_price - p.cost) ELSE 0 END), 2) AS realized_gross_profit,
        
        -- Deteksi Transaksi Rugi (Negative Margin)
        SUM(CASE WHEN oi.sale_price < p.cost THEN 1 ELSE 0 END) AS negative_margin_transactions
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    JOIN `bigquery-public-data.thelook_ecommerce.products` p 
        ON oi.product_id = p.id
    GROUP BY 1, 2, 3
    HAVING COUNT(oi.id) >= 20 -- Filter produk dengan volume penjualan signifikan
)

SELECT 
    product_category,
    product_brand,
    product_name,
    total_units_ordered,
    return_rate_pct,
    avg_sale_price,
    avg_cost,
    realized_gross_profit,
    negative_margin_transactions,
    CASE 
        WHEN realized_gross_profit > 5000 AND return_rate_pct < 10 THEN 'Tier 1: High Profit Core'
        WHEN realized_gross_profit > 5000 AND return_rate_pct >= 15 THEN 'Tier 2: High Value at Return Risk'
        WHEN realized_gross_profit <= 0 OR negative_margin_transactions > 0 THEN 'Tier 3: Margin Drainer / Loss Maker'
        ELSE 'Tier 4: Standard Contributor'
    END AS product_strategic_tier
FROM product_metrics
ORDER BY realized_gross_profit DESC;


/*
================================================================================
Phase 3: Customer Cohort Retention Analysis
Author: Rendi Dwi Andika
================================================================================
Tujuan:
Menganalisis kurva retensi pelanggan berbasis kohort bulanan (First Order Month)
hingga 6 bulan berikutnya (M0 - M6).
================================================================================
*/

WITH first_purchase AS (
    SELECT 
        user_id,
        DATE_TRUNC(MIN(DATE(created_at)), MONTH) AS cohort_month
    FROM `bigquery-public-data.thelook_ecommerce.orders`
    WHERE status NOT IN ('Cancelled', 'Returned')
    GROUP BY user_id
),

user_activities AS (
    SELECT 
        o.user_id,
        fp.cohort_month, -- Menambahkan cohort_month di sini
        DATE_TRUNC(DATE(o.created_at), MONTH) AS activity_month,
        DATE_DIFF(DATE_TRUNC(DATE(o.created_at), MONTH), fp.cohort_month, MONTH) AS month_number
    FROM `bigquery-public-data.thelook_ecommerce.orders` o
    JOIN first_purchase fp 
        ON o.user_id = fp.user_id
    WHERE o.status NOT IN ('Cancelled', 'Returned')
    GROUP BY 1, 2, 3, 4
),

cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT user_id) AS total_cohort_users
    FROM first_purchase
    GROUP BY cohort_month
),

retention_matrix AS (
    SELECT 
        ua.cohort_month,
        cs.total_cohort_users,
        ua.month_number,
        COUNT(DISTINCT ua.user_id) AS active_users
    FROM user_activities ua
    JOIN cohort_size cs 
        ON ua.cohort_month = cs.cohort_month
    WHERE ua.month_number BETWEEN 0 AND 6
      AND ua.cohort_month >= '2023-01-01'
    GROUP BY 1, 2, 3
)

SELECT 
    FORMAT_DATE('%Y-%m', cohort_month) AS cohort,
    total_cohort_users,
    ROUND(MAX(CASE WHEN month_number = 0 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m0_pct,
    ROUND(MAX(CASE WHEN month_number = 1 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m1_pct,
    ROUND(MAX(CASE WHEN month_number = 2 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m2_pct,
    ROUND(MAX(CASE WHEN month_number = 3 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m3_pct,
    ROUND(MAX(CASE WHEN month_number = 4 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m4_pct,
    ROUND(MAX(CASE WHEN month_number = 5 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m5_pct,
    ROUND(MAX(CASE WHEN month_number = 6 THEN active_users END) * 100.0 / total_cohort_users, 1) AS m6_pct
FROM retention_matrix
GROUP BY cohort_month, total_cohort_users
ORDER BY cohort_month ASC;



