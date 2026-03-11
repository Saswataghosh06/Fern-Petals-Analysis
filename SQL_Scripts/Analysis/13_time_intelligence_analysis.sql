/*
===============================================================================
Time Intelligence Analysis
===============================================================================
Purpose:
    - To identify peak ordering hours and days of the week.
    - To understand customer ordering behavior by time of day.
    - To find which occasions drive orders at specific hours.
    - Unique to FNP dataset — enabled by order_time column engineered
      in the Silver layer.

SQL Functions Used:
    - DATEPART(), DATENAME()
    - COUNT(), SUM(), AVG()
    - GROUP BY, ORDER BY

Tables Used:
    - gold.fact_orders
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Orders and revenue by hour of day
SELECT
    order_hour,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue,
    ROUND(AVG(CAST(revenue AS FLOAT)), 2)               AS avg_order_value,
    ROUND(
        CAST(COUNT(DISTINCT order_id) AS FLOAT)
        / SUM(COUNT(DISTINCT order_id)) OVER () * 100
    , 2)                                                AS orders_pct
FROM gold.fact_orders
GROUP BY order_hour
ORDER BY order_hour;

-- Peak hour of the day by orders
SELECT TOP 5
    order_hour,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue
FROM gold.fact_orders
GROUP BY order_hour
ORDER BY total_orders DESC;

-- Orders and revenue by day of week
SELECT
    order_day,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue,
    ROUND(AVG(CAST(revenue AS FLOAT)), 2)               AS avg_order_value,
    ROUND(
        CAST(COUNT(DISTINCT order_id) AS FLOAT)
        / SUM(COUNT(DISTINCT order_id)) OVER () * 100
    , 2)                                                AS orders_pct
FROM gold.fact_orders
GROUP BY order_day
ORDER BY total_orders DESC;

-- Orders by day of week in correct calendar order
SELECT
    order_day,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue
FROM gold.fact_orders
GROUP BY order_day
ORDER BY
    CASE order_day
        WHEN 'Monday'    THEN 1
        WHEN 'Tuesday'   THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday'  THEN 4
        WHEN 'Friday'    THEN 5
        WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'    THEN 7
    END;

-- Orders by hour and occasion
-- Shows which occasions drive late night vs morning orders
SELECT
    occasion,
    order_hour,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue
FROM gold.fact_orders
GROUP BY
    occasion,
    order_hour
ORDER BY
    occasion,
    order_hour;

-- Hour buckets — morning, afternoon, evening, night
SELECT
    CASE
        WHEN order_hour BETWEEN 5  AND 11 THEN 'Morning (5am-11am)'
        WHEN order_hour BETWEEN 12 AND 16 THEN 'Afternoon (12pm-4pm)'
        WHEN order_hour BETWEEN 17 AND 20 THEN 'Evening (5pm-8pm)'
        ELSE 'Night (9pm-4am)'
    END                                                 AS time_bucket,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue,
    ROUND(AVG(CAST(revenue AS FLOAT)), 2)               AS avg_order_value,
    ROUND(
        CAST(COUNT(DISTINCT order_id) AS FLOAT)
        / SUM(COUNT(DISTINCT order_id)) OVER () * 100
    , 2)                                                AS orders_pct
FROM gold.fact_orders
GROUP BY
    CASE
        WHEN order_hour BETWEEN 5  AND 11 THEN 'Morning (5am-11am)'
        WHEN order_hour BETWEEN 12 AND 16 THEN 'Afternoon (12pm-4pm)'
        WHEN order_hour BETWEEN 17 AND 20 THEN 'Evening (5pm-8pm)'
        ELSE 'Night (9pm-4am)'
    END
ORDER BY total_orders DESC;

-- Peak day and hour combination
-- Finds the single busiest hour-day slot of the entire year
SELECT TOP 10
    order_day,
    order_hour,
    COUNT(DISTINCT order_id)                            AS total_orders,
    SUM(revenue)                                        AS total_revenue
FROM gold.fact_orders
GROUP BY
    order_day,
    order_hour
ORDER BY total_orders DESC;