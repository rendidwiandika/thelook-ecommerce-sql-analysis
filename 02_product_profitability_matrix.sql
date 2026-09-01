/*
Product Portfolio Profitability & Anomaly Detection
Objective:
Categorize product performance into a Risk & Profitability Matrix:
1. High Margin - Low Return (Star)
2. Low Margin - High Return (Toxic / Margin Drainer)
3. Negative Profit Anomaly (Pricing issues / Loss maker)
================================================================================
*/

WITH product_metrics AS (
    SELECT 
        p.category AS product_category,
        p.brand AS product_brand,
        p.name AS product_name,
        COUNT(oi.id) AS total_units_ordered,
        
        -- return rate tracking
        COUNT(CASE WHEN LOWER(oi.status) = 'returned' THEN 1 END) AS return_count,
        ROUND(COUNT(CASE WHEN LOWER(oi.status) = 'returned' THEN 1 END) / NULLIF(COUNT(oi.id), 0) * 100, 2) AS return_rate_pct,
        
        -- core financial metrics
        ROUND(AVG(oi.sale_price), 2) AS avg_sale_price,
        ROUND(AVG(p.cost), 2) AS avg_cost,
        ROUND(SUM(CASE WHEN LOWER(oi.status) = 'complete' THEN (oi.sale_price - p.cost) ELSE 0 END), 2) AS realized_gross_profit,
        
        -- flag transactions where items were sold below cost
        SUM(CASE WHEN oi.sale_price < p.cost THEN 1 ELSE 0 END) AS negative_margin_transactions
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    JOIN `bigquery-public-data.thelook_ecommerce.products` p 
        ON oi.product_id = p.id
    GROUP BY 1, 2, 3
    -- exclude low-volume products to avoid skewed return rates
    HAVING COUNT(oi.id) >= 20 
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
    -- risk and profitability classification
    CASE 
        WHEN realized_gross_profit > 5000 AND return_rate_pct < 10 THEN 'Tier 1: High Profit Core'
        WHEN realized_gross_profit > 5000 AND return_rate_pct >= 15 THEN 'Tier 2: High Value at Return Risk'
        WHEN realized_gross_profit <= 0 OR negative_margin_transactions > 0 THEN 'Tier 3: Margin Drainer / Loss Maker'
        ELSE 'Tier 4: Standard Contributor'
    END AS product_strategic_tier
FROM product_metrics
ORDER BY realized_gross_profit DESC;