/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure and unique values within dimension tables.
    - To understand the range of categorical data available for analysis.

SQL Functions Used:
    - DISTINCT
    - ORDER BY
    - COUNT()

Tables Used:
    - gold.dim_customers
    - gold.dim_products
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Retrieve all unique cities where customers are located
SELECT DISTINCT
    city
FROM gold.dim_customers
ORDER BY city;

-- Retrieve total customers per city
SELECT
    city,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY city
ORDER BY total_customers DESC;

-- Retrieve all unique gender values
SELECT DISTINCT
    gender
FROM gold.dim_customers
ORDER BY gender;

-- Retrieve all unique product categories
SELECT DISTINCT
    category
FROM gold.dim_products
ORDER BY category;

-- Retrieve all unique occasions from products
SELECT DISTINCT
    occasion
FROM gold.dim_products
ORDER BY occasion;

-- Retrieve full product dimension — category, product name, price
SELECT DISTINCT
    category,
    product_name,
    price_inr
FROM gold.dim_products
ORDER BY category, product_name;

-- Retrieve all unique occasions from fact_orders
-- (cross check against product occasions)
SELECT DISTINCT
    occasion
FROM gold.fact_orders
ORDER BY occasion;