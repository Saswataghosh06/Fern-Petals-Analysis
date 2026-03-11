/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank products, customers, and occasions by performance.
    - To identify top performers and worst performers.
    - To find the best selling product per occasion.

SQL Functions Used:
    - RANK(), DENSE_RANK(), ROW_NUMBER()
    - TOP
    - GROUP BY, ORDER BY

Tables Used:
    - gold.fact_orders
    - gold.dim_customers
    - gold.dim_products
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Top 10 products by revenue
SELECT TOP 10
    p.product_name,
    p.category,
    SUM(f.revenue)              AS total_revenue,
    COUNT(DISTINCT f.order_id)  AS total_orders
FROM gold.fact_orders f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name,
    p.category
ORDER BY total_revenue DESC;

-- Top 10 products by revenue using RANK window function
SELECT *
FROM (
    SELECT
        p.product_name,
        p.category,
        SUM(f.revenue)  AS total_revenue,
        RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS revenue_rank
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY
        p.product_name,
        p.category
) AS ranked_products
WHERE revenue_rank <= 10;

-- Bottom 5 products by revenue
SELECT TOP 5
    p.product_name,
    p.category,
    SUM(f.revenue)  AS total_revenue,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM gold.fact_orders f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name,
    p.category
ORDER BY total_revenue ASC;

-- Best selling product per occasion using RANK()
SELECT *
FROM (
    SELECT
        f.occasion,
        p.product_name,
        p.category,
        SUM(f.revenue)  AS total_revenue,
        RANK() OVER (
            PARTITION BY f.occasion
            ORDER BY SUM(f.revenue) DESC
        ) AS rank_within_occasion
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY
        f.occasion,
        p.product_name,
        p.category
) AS occasion_ranked
WHERE rank_within_occasion = 1
ORDER BY total_revenue DESC;

-- Top 10 customers by revenue
SELECT TOP 10
    c.customer_key,
    c.name,
    c.city,
    c.gender,
    SUM(f.revenue)              AS total_revenue,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    ROUND(SUM(f.revenue) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.name,
    c.city,
    c.gender
ORDER BY total_revenue DESC;

-- Bottom 5 customers by revenue
SELECT TOP 5
    c.customer_key,
    c.name,
    c.city,
    SUM(f.revenue)              AS total_revenue,
    COUNT(DISTINCT f.order_id)  AS total_orders
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_key,
    c.name,
    c.city
ORDER BY total_revenue ASC;

-- Top 5 occasions by total orders
SELECT TOP 5
    occasion,
    COUNT(DISTINCT order_id)    AS total_orders,
    SUM(revenue)                AS total_revenue
FROM gold.fact_orders
GROUP BY occasion
ORDER BY total_orders DESC;

-- Top 10 cities by total orders
SELECT TOP 10
    c.city,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    SUM(f.revenue)              AS total_revenue
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.city
ORDER BY total_orders DESC;