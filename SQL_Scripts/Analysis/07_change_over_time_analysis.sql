/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - To identify seasonality and peak periods.
    - To measure monthly performance across the full year.

SQL Functions Used:
    - FORMAT(), DATETRUNC(), DATEPART(), YEAR(), MONTH()
    - SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY

Tables Used:
    - gold.fact_orders
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Monthly revenue, orders, and quantity trend
SELECT
    FORMAT(order_date, 'yyyy-MMM')      AS order_month,
    SUM(revenue)                        AS total_revenue,
    COUNT(DISTINCT order_id)            AS total_orders,
    SUM(quantity)                       AS total_quantity,
    ROUND(SUM(revenue) /
        COUNT(DISTINCT order_id), 2)    AS avg_order_value
FROM gold.fact_orders
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY MIN(order_date);

-- Monthly revenue using DATETRUNC for clean date grouping
SELECT
    DATETRUNC(MONTH, order_date)        AS order_month,
    SUM(revenue)                        AS total_revenue,
    COUNT(DISTINCT order_id)            AS total_orders,
    SUM(quantity)                       AS total_quantity
FROM gold.fact_orders
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date);

-- Monthly revenue by occasion
-- Shows which occasions drive which months
SELECT
    FORMAT(order_date, 'yyyy-MMM')      AS order_month,
    occasion,
    SUM(revenue)                        AS total_revenue,
    COUNT(DISTINCT order_id)            AS total_orders
FROM gold.fact_orders
WHERE order_date IS NOT NULL
GROUP BY
    FORMAT(order_date, 'yyyy-MMM'),
    occasion
ORDER BY MIN(order_date), total_revenue DESC;

-- Quarterly revenue breakdown
SELECT
    YEAR(order_date)                    AS order_year,
    DATEPART(QUARTER, order_date)       AS order_quarter,
    SUM(revenue)                        AS total_revenue,
    COUNT(DISTINCT order_id)            AS total_orders
FROM gold.fact_orders
WHERE order_date IS NOT NULL
GROUP BY
    YEAR(order_date),
    DATEPART(QUARTER, order_date)
ORDER BY
    order_year,
    order_quarter;

-- Monthly revenue by category
SELECT
    FORMAT(f.order_date, 'yyyy-MMM')    AS order_month,
    p.category,
    SUM(f.revenue)                      AS total_revenue
FROM gold.fact_orders f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY
    FORMAT(f.order_date, 'yyyy-MMM'),
    p.category
ORDER BY MIN(f.order_date), total_revenue DESC;