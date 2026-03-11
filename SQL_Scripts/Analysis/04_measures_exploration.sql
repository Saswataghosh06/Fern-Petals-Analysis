/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics for quick business insights.
    - To establish the baseline KPIs for the entire dataset.
    - To identify anomalies or unexpected values in key measures.

SQL Functions Used:
    - SUM(), COUNT(), AVG(), MIN(), MAX()

Tables Used:
    - gold.fact_orders
    - gold.dim_products
    - gold.dim_customers
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Total Revenue
SELECT SUM(revenue) AS total_revenue FROM gold.fact_orders;

-- Total Orders
SELECT COUNT(DISTINCT order_id) AS total_orders FROM gold.fact_orders;

-- Total Quantity Sold
SELECT SUM(quantity) AS total_quantity FROM gold.fact_orders;

-- Average Order Value (AOV)
SELECT
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM gold.fact_orders;

-- Average Delivery Days
SELECT
    ROUND(AVG(CAST(delivery_days AS FLOAT)), 2) AS avg_delivery_days
FROM gold.fact_orders;

-- Total Products
SELECT COUNT(DISTINCT product_name) AS total_products FROM gold.dim_products;

-- Total Customers
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.dim_customers;

-- Total Customers Who Placed at Least One Order
SELECT COUNT(DISTINCT customer_key) AS active_customers FROM gold.fact_orders;

-- Total Occasions
SELECT COUNT(DISTINCT occasion) AS total_occasions FROM gold.fact_orders;

-- Total Categories
SELECT COUNT(DISTINCT category) AS total_categories FROM gold.dim_products;

-- Price Range of Products
SELECT
    MIN(price_inr) AS min_price,
    MAX(price_inr) AS max_price,
    ROUND(AVG(price_inr), 2) AS avg_price
FROM gold.dim_products;

-- Full KPI Summary -- single result set for dashboards and reports

SELECT 'Total Revenue'       AS measure_name, CAST(SUM(revenue) AS NVARCHAR)                               AS measure_value FROM gold.fact_orders
UNION ALL
SELECT 'Total Orders',        CAST(COUNT(DISTINCT order_id) AS NVARCHAR)                                   FROM gold.fact_orders
UNION ALL
SELECT 'Total Quantity',      CAST(SUM(quantity) AS NVARCHAR)                                              FROM gold.fact_orders
UNION ALL
SELECT 'Avg Order Value',     CAST(ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS NVARCHAR)          FROM gold.fact_orders
UNION ALL
SELECT 'Avg Delivery Days',   CAST(ROUND(AVG(CAST(delivery_days AS FLOAT)), 2) AS NVARCHAR)                FROM gold.fact_orders
UNION ALL
SELECT 'Total Products',      CAST(COUNT(DISTINCT product_name) AS NVARCHAR)                               FROM gold.dim_products
UNION ALL
SELECT 'Total Customers',     CAST(COUNT(DISTINCT customer_key) AS NVARCHAR)                               FROM gold.dim_customers
UNION ALL
SELECT 'Total Occasions',     CAST(COUNT(DISTINCT occasion) AS NVARCHAR)                                   FROM gold.fact_orders
UNION ALL
SELECT 'Total Categories',    CAST(COUNT(DISTINCT category) AS NVARCHAR)                                   FROM gold.dim_products;