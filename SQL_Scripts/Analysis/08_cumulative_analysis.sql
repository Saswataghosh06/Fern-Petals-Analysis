/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals and moving averages for key metrics.
    - To track cumulative performance over time.
    - To identify long term revenue growth patterns.

SQL Functions Used:
    - SUM() OVER()
    - AVG() OVER()
    - DATETRUNC()

Tables Used:
    - gold.fact_orders
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Running total of revenue and moving average of AOV over months
SELECT
    order_month,
    total_revenue,
    total_orders,
    SUM(total_revenue)  OVER (ORDER BY order_month)             AS running_total_revenue,
    AVG(avg_order_value) OVER (ORDER BY order_month)            AS moving_avg_order_value,
    ROUND(SUM(total_revenue) OVER (ORDER BY order_month) /
          SUM(total_revenue) OVER () * 100, 2)                  AS cumulative_revenue_pct
FROM (
    SELECT
        DATETRUNC(MONTH, order_date)                            AS order_month,
        SUM(revenue)                                            AS total_revenue,
        COUNT(DISTINCT order_id)                                AS total_orders,
        ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2)       AS avg_order_value
    FROM gold.fact_orders
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) AS monthly_stats
ORDER BY order_month;

-- Running total of orders over months
SELECT
    order_month,
    total_orders,
    SUM(total_orders) OVER (ORDER BY order_month)               AS running_total_orders
FROM (
    SELECT
        DATETRUNC(MONTH, order_date)                            AS order_month,
        COUNT(DISTINCT order_id)                                AS total_orders
    FROM gold.fact_orders
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) AS monthly_orders
ORDER BY order_month;

-- Cumulative revenue by occasion
-- Shows which occasion crosses ₹5L first
SELECT
    occasion,
    order_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        PARTITION BY occasion
        ORDER BY order_month
    )                                                           AS running_total_by_occasion
FROM (
    SELECT
        occasion,
        DATETRUNC(MONTH, order_date)                            AS order_month,
        SUM(revenue)                                            AS monthly_revenue
    FROM gold.fact_orders
    WHERE order_date IS NOT NULL
    GROUP BY
        occasion,
        DATETRUNC(MONTH, order_date)
) AS occasion_monthly
ORDER BY occasion, order_month;