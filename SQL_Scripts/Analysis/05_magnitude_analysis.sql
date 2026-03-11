/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - To understand revenue and order distribution across categories,
      occasions, cities, and customer segments.

SQL Functions Used:
    - SUM(), COUNT(), AVG(), ROUND()
    - GROUP BY, ORDER BY

Tables Used:
    - gold.fact_orders
    - gold.dim_customers
    - gold.dim_products
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Total revenue and orders by occasion
SELECT
    occasion,
    SUM(revenue)            AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM gold.fact_orders
GROUP BY occasion
ORDER BY total_revenue DESC;

-- Total revenue and orders by product category
SELECT
    p.category,
    SUM(f.revenue)              AS total_revenue,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    SUM(f.quantity)             AS total_quantity,
    ROUND(AVG(p.price_inr), 2)  AS avg_price
FROM gold.fact_orders f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Total revenue and orders by city (top 10)
SELECT TOP 10
    c.city,
    SUM(f.revenue)              AS total_revenue,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    ROUND(SUM(f.revenue) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.city
ORDER BY total_revenue DESC;

-- Total revenue and orders by gender
SELECT
    c.gender,
    SUM(f.revenue)              AS total_revenue,
    COUNT(DISTINCT f.order_id)  AS total_orders,
    ROUND(SUM(f.revenue) / COUNT(DISTINCT f.order_id), 2) AS avg_order_value
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.gender
ORDER BY total_revenue DESC;

-- Total quantity sold by product category
SELECT
    p.category,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_orders f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_quantity DESC;

-- Total revenue per customer (top 10)
SELECT TOP 10
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
ORDER BY total_revenue DESC;

-- Average order value by occasion
SELECT
    occasion,
    ROUND(AVG(revenue), 2) AS avg_order_value
FROM gold.fact_orders
GROUP BY occasion
ORDER BY avg_order_value DESC;

-- Total orders by location
SELECT
    location,
    COUNT(DISTINCT order_id)    AS total_orders,
    SUM(revenue)                AS total_revenue
FROM gold.fact_orders
GROUP BY location
ORDER BY total_orders DESC;