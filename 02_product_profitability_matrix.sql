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
        -- cost is a fixed attribute per product (not a value that varies per order),
        -- so ANY_VALUE is used instead of AVG to make the intent explicit
        ROUND(ANY_VALUE(p.cost), 2) AS product_cost,
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
    product_cost,
    realized_gross_profit,
    negative_margin_transactions,
    -- risk and profitability classification
    -- IMPORTANT: the loss-maker check must be evaluated FIRST. CASE WHEN stops
    -- at the first matching condition, so if the profit/return-rate checks were
    -- placed above it, a product with high profit AND a negative-margin
    -- transaction would be wrongly classified as "Tier 1" instead of "Tier 3".
    -- Threshold values are derived from the actual percentile distribution of
    -- the catalog (see 00_profitability_threshold_distribution.sql):
    --   - $300 profit  ≈ P80 of realized_gross_profit (top 20% of products)
    --   - 18% return rate ≈ P90 of return_rate_pct (worse than 90% of products)
    CASE 
        WHEN realized_gross_profit <= 0 OR negative_margin_transactions > 0 THEN 'Tier 3: Margin Drainer / Loss Maker'
        WHEN realized_gross_profit > 300 AND return_rate_pct < 10 THEN 'Tier 1: High Profit Core'
        WHEN realized_gross_profit > 300 AND return_rate_pct >= 18 THEN 'Tier 2: High Value at Return Risk'
        ELSE 'Tier 4: Standard Contributor'
    END AS product_strategic_tier
FROM product_metrics
ORDER BY realized_gross_profit DESC;