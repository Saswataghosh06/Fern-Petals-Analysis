/*
===============================================================================
Delivery Analysis
===============================================================================
Purpose:
    - To measure delivery performance across cities and occasions.
    - To identify operational bottlenecks in the delivery pipeline.
    - To understand the relationship between delivery speed and revenue.

SQL Functions Used:
    - AVG(), MIN(), MAX(), COUNT()
    - DATEDIFF()
    - CASE: Delivery speed segmentation
    - GROUP BY, ORDER BY

Tables Used:
    - gold.fact_orders
    - gold.dim_customers
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Overall delivery summary
SELECT
    MIN(delivery_days)                          AS min_delivery_days,
    MAX(delivery_days)                          AS max_delivery_days,
    ROUND(AVG(CAST(delivery_days AS FLOAT)), 2) AS avg_delivery_days
FROM gold.fact_orders;

-- Average delivery days by city (worst 10 cities)
SELECT TOP 10
    c.city,
    COUNT(DISTINCT f.order_id)                          AS total_orders,
    ROUND(AVG(CAST(f.delivery_days AS FLOAT)), 2)       AS avg_delivery_days,
    MIN(f.delivery_days)                                AS min_delivery_days,
    MAX(f.delivery_days)                                AS max_delivery_days
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.city
ORDER BY avg_delivery_days DESC;

-- Best 10 cities by delivery speed
SELECT TOP 10
    c.city,
    COUNT(DISTINCT f.order_id)                          AS total_orders,
    ROUND(AVG(CAST(f.delivery_days AS FLOAT)), 2)       AS avg_delivery_days
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.city
ORDER BY avg_delivery_days ASC;

-- Delivery speed distribution
SELECT
    CASE
        WHEN delivery_days = 0              THEN 'Same Day'
        WHEN delivery_days BETWEEN 1 AND 3  THEN 'Fast (1-3 days)'
        WHEN delivery_days BETWEEN 4 AND 7  THEN 'Standard (4-7 days)'
        ELSE 'Slow (8+ days)'
    END                                             AS delivery_segment,
    COUNT(order_id)                                 AS total_orders,
    ROUND(
        CAST(COUNT(order_id) AS FLOAT)
        / SUM(COUNT(order_id)) OVER () * 100
    , 2)                                            AS orders_pct,
    ROUND(AVG(CAST(revenue AS FLOAT)), 2)           AS avg_order_value,
    SUM(revenue)                                    AS total_revenue
FROM gold.fact_orders
GROUP BY
    CASE
        WHEN delivery_days = 0              THEN 'Same Day'
        WHEN delivery_days BETWEEN 1 AND 3  THEN 'Fast (1-3 days)'
        WHEN delivery_days BETWEEN 4 AND 7  THEN 'Standard (4-7 days)'
        ELSE 'Slow (8+ days)'
    END
ORDER BY total_orders DESC;

-- Average delivery days by occasion
-- Shows if high value occasions get faster delivery
SELECT
    occasion,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(AVG(CAST(delivery_days AS FLOAT)), 2)         AS avg_delivery_days,
    ROUND(AVG(CAST(revenue AS FLOAT)), 2)               AS avg_order_value,
    SUM(revenue)                                        AS total_revenue
FROM gold.fact_orders
GROUP BY occasion
ORDER BY avg_delivery_days ASC;

-- Delivery days frequency distribution
-- Shows exactly how many orders took 1 day, 2 days, 3 days etc
SELECT
    delivery_days,
    COUNT(order_id)                                     AS total_orders,
    ROUND(
        CAST(COUNT(order_id) AS FLOAT)
        / SUM(COUNT(order_id)) OVER () * 100
    , 2)                                                AS orders_pct
FROM gold.fact_orders
GROUP BY delivery_days
ORDER BY delivery_days;

-- Monthly average delivery days
-- Shows if delivery gets worse during peak months
SELECT
    FORMAT(order_date, 'yyyy-MMM')                      AS order_month,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(AVG(CAST(delivery_days AS FLOAT)), 2)         AS avg_delivery_days
FROM gold.fact_orders
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY MIN(order_date);