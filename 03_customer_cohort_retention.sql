/*
Customer Cohort Retention Analysis
Objective:
Analyze customer retention curves based on monthly cohorts (First Order Month) 
tracking activity up to 6 months post-acquisition (M0 - M6).
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
        fp.cohort_month, -- include cohort base month
        DATE_TRUNC(DATE(o.created_at), MONTH) AS activity_month,
        DATE_DIFF(DATE_TRUNC(DATE(o.created_at), MONTH), fp.cohort_month, MONTH) AS month_number
    FROM `bigquery-public-data.thelook_ecommerce.orders` o
    JOIN first_purchase fp 
        ON o.user_id = fp.user_id
    -- count only successful transactions for retention
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