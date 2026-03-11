/*
===============================================================================
Date Range Exploration
===============================================================================
Purpose:
    - To determine the temporal boundaries of the dataset.
    - To understand the full range of historical data available.
    - To identify gaps or anomalies in the date range.

SQL Functions Used:
    - MIN(), MAX()
    - DATEDIFF()
    - DATENAME(), DATEPART()

Tables Used:
    - gold.fact_orders
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- First and last order date with total duration in months
SELECT
    MIN(order_date)                                    AS first_order_date,
    MAX(order_date)                                    AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date))  AS order_range_months,
    DATEDIFF(DAY,   MIN(order_date), MAX(order_date))  AS order_range_days
FROM gold.fact_orders;

-- First and last delivery date with total duration
SELECT
    MIN(delivery_date)                                         AS first_delivery_date,
    MAX(delivery_date)                                         AS last_delivery_date,
    DATEDIFF(MONTH, MIN(delivery_date), MAX(delivery_date))    AS delivery_range_months
FROM gold.fact_orders;

-- How many distinct months of data do we have?
SELECT
    COUNT(DISTINCT FORMAT(order_date, 'yyyy-MM')) AS distinct_months
FROM gold.fact_orders;

-- How many orders per month -- confirms no missing months
SELECT
    FORMAT(order_date, 'yyyy-MMM')  AS order_month,
    COUNT(order_id)                 AS total_orders
FROM gold.fact_orders
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY MIN(order_date);

-- Earliest and latest order per occasion
SELECT
    occasion,
    MIN(order_date)  AS first_order_date,
    MAX(order_date)  AS last_order_date
FROM gold.fact_orders
GROUP BY occasion
ORDER BY occasion;

-- Delivery date range check
-- Confirms no delivery dates before order dates (data quality)
SELECT
    COUNT(*) AS invalid_delivery_records
FROM gold.fact_orders
WHERE delivery_date < order_date;