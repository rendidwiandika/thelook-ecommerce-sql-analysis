/*
Financial Leakage & Fulfillment Health Audit
Objective:
Analyze the gap between Gross Merchandise Value (GMV) and Realized Revenue, 
and identify revenue leakage caused by cancelled and returned orders.
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
        
        -- calculate delivery & handling times
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
        
        -- realized metrics (completed and shipped orders only)
        ROUND(SUM(CASE WHEN status IN ('complete', 'shipped') THEN sale_price ELSE 0 END), 2) AS realized_revenue,
        ROUND(SUM(CASE WHEN status IN ('complete', 'shipped') THEN (sale_price - product_cost) ELSE 0 END), 2) AS realized_net_profit,
        
        -- revenue lost to cancellations and returns
        ROUND(SUM(CASE WHEN status = 'cancelled' THEN sale_price ELSE 0 END), 2) AS cancelled_loss_value,
        ROUND(SUM(CASE WHEN status = 'returned' THEN sale_price ELSE 0 END), 2) AS returned_loss_value,
        
        -- leakage percentage relative to gmv
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
    -- actual profit margin on realized revenue
    ROUND((realized_net_profit / NULLIF(realized_revenue, 0)) * 100, 2) AS realized_profit_margin_pct
FROM monthly_leakage_audit
WHERE year_month >= '2023-01' -- filter out older, unstable data periods
ORDER BY year_month ASC;