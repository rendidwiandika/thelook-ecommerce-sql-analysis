/*
Profitability & Return-Rate Threshold Distribution
Objective:
Determine the percentile distribution of product-level profit and return rate
across the catalog, to justify the thresholds used to classify products into
tiers in 02_product_profitability_matrix.sql (rather than picking round
numbers arbitrarily).
================================================================================
*/

WITH product_metrics AS (
    SELECT 
        p.category AS product_category,
        p.brand AS product_brand,
        p.name AS product_name,
        COUNT(oi.id) AS total_units_ordered,
        ROUND(COUNT(CASE WHEN LOWER(oi.status) = 'returned' THEN 1 END) / NULLIF(COUNT(oi.id), 0) * 100, 2) AS return_rate_pct,
        ROUND(SUM(CASE WHEN LOWER(oi.status) = 'complete' THEN (oi.sale_price - p.cost) ELSE 0 END), 2) AS realized_gross_profit
    FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
    JOIN `bigquery-public-data.thelook_ecommerce.products` p 
        ON oi.product_id = p.id
    GROUP BY 1, 2, 3
    HAVING COUNT(oi.id) >= 20 -- same volume filter as the main tiering query
),

-- rank every product's profit and return rate against the rest of the catalog
percentile_ranks AS (
    SELECT
        product_category,
        product_brand,
        product_name,
        total_units_ordered,
        return_rate_pct,
        realized_gross_profit,
        PERCENT_RANK() OVER (ORDER BY realized_gross_profit) AS profit_percentile,
        PERCENT_RANK() OVER (ORDER BY return_rate_pct) AS return_rate_percentile
    FROM product_metrics
)

-- summary: what profit / return-rate value sits at each key percentile
-- use this output to decide (and justify) the cutoffs used in the tier CASE WHEN
SELECT
    'realized_gross_profit' AS metric,
    ROUND(APPROX_QUANTILES(realized_gross_profit, 100)[OFFSET(50)], 2) AS p50,
    ROUND(APPROX_QUANTILES(realized_gross_profit, 100)[OFFSET(75)], 2) AS p75,
    ROUND(APPROX_QUANTILES(realized_gross_profit, 100)[OFFSET(80)], 2) AS p80,
    ROUND(APPROX_QUANTILES(realized_gross_profit, 100)[OFFSET(90)], 2) AS p90
FROM product_metrics

UNION ALL

SELECT
    'return_rate_pct' AS metric,
    ROUND(APPROX_QUANTILES(return_rate_pct, 100)[OFFSET(50)], 2) AS p50,
    ROUND(APPROX_QUANTILES(return_rate_pct, 100)[OFFSET(75)], 2) AS p75,
    ROUND(APPROX_QUANTILES(return_rate_pct, 100)[OFFSET(80)], 2) AS p80,
    ROUND(APPROX_QUANTILES(return_rate_pct, 100)[OFFSET(90)], 2) AS p90
FROM product_metrics;

-- Usage: run this first. Whatever value comes back at, say, P80 for
-- realized_gross_profit becomes your justified "high profit" cutoff, and the
-- P90 value for return_rate_pct becomes your "high risk" cutoff. Plug those
-- numbers into 02_product_profitability_matrix.sql and cite the percentile
-- in the README instead of an unexplained round number.
