/*
===============================================================================
Part to Whole Analysis
===============================================================================
Purpose:
    - To compare the contribution of each dimension to overall performance.
    - To understand which occasions, categories, and cities drive the most
      revenue as a percentage of total.
    - Useful for identifying concentration risk and growth opportunities.

SQL Functions Used:
    - SUM() OVER(): Calculates overall totals for percentage computation.
    - ROUND(), CAST()
    - GROUP BY, ORDER BY

Tables Used:
    - gold.fact_orders
    - gold.dim_customers
    - gold.dim_products
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Revenue contribution by occasion
WITH occasion_sales AS (
    SELECT
        occasion,
        SUM(revenue)                AS total_revenue,
        COUNT(DISTINCT order_id)    AS total_orders
    FROM gold.fact_orders
    GROUP BY occasion
)
SELECT
    occasion,
    total_revenue,
    total_orders,
    SUM(total_revenue) OVER ()      AS overall_revenue,
    ROUND(
        CAST(total_revenue AS FLOAT)
        / SUM(total_revenue) OVER () * 100
    , 2)                            AS revenue_pct,
    ROUND(
        CAST(total_orders AS FLOAT)
        / SUM(total_orders) OVER () * 100
    , 2)                            AS orders_pct
FROM occasion_sales
ORDER BY total_revenue DESC;

-- Revenue contribution by category
WITH category_sales AS (
    SELECT
        p.category,
        SUM(f.revenue)              AS total_revenue,
        COUNT(DISTINCT f.order_id)  AS total_orders
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_revenue,
    total_orders,
    SUM(total_revenue) OVER ()      AS overall_revenue,
    ROUND(
        CAST(total_revenue AS FLOAT)
        / SUM(total_revenue) OVER () * 100
    , 2)                            AS revenue_pct,
    ROUND(
        CAST(total_orders AS FLOAT)
        / SUM(total_orders) OVER () * 100
    , 2)                            AS orders_pct
FROM category_sales
ORDER BY total_revenue DESC;

-- Revenue contribution by city (top 10)
WITH city_sales AS (
    SELECT
        c.city,
        SUM(f.revenue)              AS total_revenue,
        COUNT(DISTINCT f.order_id)  AS total_orders
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.city
)
SELECT TOP 10
    city,
    total_revenue,
    total_orders,
    SUM(total_revenue) OVER ()      AS overall_revenue,
    ROUND(
        CAST(total_revenue AS FLOAT)
        / SUM(total_revenue) OVER () * 100
    , 2)                            AS revenue_pct
FROM city_sales
ORDER BY total_revenue DESC;

-- Revenue contribution by gender
WITH gender_sales AS (
    SELECT
        c.gender,
        SUM(f.revenue)              AS total_revenue,
        COUNT(DISTINCT f.order_id)  AS total_orders
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.gender
)
SELECT
    gender,
    total_revenue,
    total_orders,
    SUM(total_revenue) OVER ()      AS overall_revenue,
    ROUND(
        CAST(total_revenue AS FLOAT)
        / SUM(total_revenue) OVER () * 100
    , 2)                            AS revenue_pct
FROM gender_sales
ORDER BY total_revenue DESC;

-- Top 5 occasions + Other — simplified for donut chart in Power BI
WITH occasion_sales AS (
    SELECT
        occasion,
        SUM(revenue) AS total_revenue
    FROM gold.fact_orders
    GROUP BY occasion
),
ranked AS (
    SELECT
        occasion,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM occasion_sales
)
SELECT
    CASE WHEN rnk <= 5 THEN occasion ELSE 'Other' END   AS occasion_group,
    SUM(total_revenue)                                  AS total_revenue,
    ROUND(
        CAST(SUM(total_revenue) AS FLOAT)
        / SUM(SUM(total_revenue)) OVER () * 100
    , 2)                                                AS revenue_pct
FROM ranked
GROUP BY CASE WHEN rnk <= 5 THEN occasion ELSE 'Other' END
ORDER BY total_revenue DESC;