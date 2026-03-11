/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - To segment products by price range.
    - To segment customers by order frequency and spending behavior.
    - To segment orders by delivery speed.

SQL Functions Used:
    - CASE: Custom segmentation logic.
    - GROUP BY: Groups data into segments.
    - CTEs: Builds segmentation base before aggregating.

Tables Used:
    - gold.fact_orders
    - gold.dim_customers
    - gold.dim_products
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Segment products by price range
-- Shows how FNP's catalog is distributed across price bands
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        category,
        price_inr,
        CASE
            WHEN price_inr < 500  THEN 'Budget (Below ₹500)'
            WHEN price_inr BETWEEN 500  AND 1000 THEN 'Mid Range (₹500-₹1000)'
            WHEN price_inr BETWEEN 1001 AND 1500 THEN 'Premium (₹1001-₹1500)'
            ELSE 'Luxury (Above ₹1500)'
        END AS price_segment
    FROM gold.dim_products
)
SELECT
    price_segment,
    COUNT(product_key)      AS total_products,
    ROUND(AVG(price_inr), 2) AS avg_price
FROM product_segments
GROUP BY price_segment
ORDER BY avg_price;

-- Segment products by price range with category breakdown
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        category,
        price_inr,
        CASE
            WHEN price_inr < 500  THEN 'Budget (Below ₹500)'
            WHEN price_inr BETWEEN 500  AND 1000 THEN 'Mid Range (₹500-₹1000)'
            WHEN price_inr BETWEEN 1001 AND 1500 THEN 'Premium (₹1001-₹1500)'
            ELSE 'Luxury (Above ₹1500)'
        END AS price_segment
    FROM gold.dim_products
)
SELECT
    price_segment,
    category,
    COUNT(product_key)      AS total_products
FROM product_segments
GROUP BY price_segment, category
ORDER BY price_segment, total_products DESC;

-- Segment customers by total orders (frequency segments)
WITH customer_orders AS (
    SELECT
        c.customer_key,
        c.name,
        c.city,
        c.gender,
        COUNT(DISTINCT f.order_id)  AS total_orders,
        SUM(f.revenue)              AS total_revenue
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key,
        c.name,
        c.city,
        c.gender
)
SELECT
    customer_key,
    name,
    city,
    gender,
    total_orders,
    total_revenue,
    CASE
        WHEN total_orders >= 15 THEN 'Loyal (15+ orders)'
        WHEN total_orders BETWEEN 10 AND 14 THEN 'Regular (10-14 orders)'
        WHEN total_orders BETWEEN 5  AND 9  THEN 'Occasional (5-9 orders)'
        ELSE 'One Time (Below 5 orders)'
    END AS customer_segment
FROM customer_orders
ORDER BY total_orders DESC;

-- Count customers per segment
WITH customer_orders AS (
    SELECT
        f.customer_key,
        COUNT(DISTINCT f.order_id) AS total_orders,
        SUM(f.revenue)             AS total_revenue
    FROM gold.fact_orders f
    GROUP BY f.customer_key
),
segmented AS (
    SELECT
        customer_key,
        total_orders,
        total_revenue,
        CASE
            WHEN total_orders >= 15 THEN 'Loyal (15+ orders)'
            WHEN total_orders BETWEEN 10 AND 14 THEN 'Regular (10-14 orders)'
            WHEN total_orders BETWEEN 5  AND 9  THEN 'Occasional (5-9 orders)'
            ELSE 'One Time (Below 5 orders)'
        END AS customer_segment
    FROM customer_orders
)
SELECT
    customer_segment,
    COUNT(customer_key)         AS total_customers,
    SUM(total_revenue)          AS total_revenue,
    ROUND(AVG(total_revenue),2) AS avg_revenue_per_customer
FROM segmented
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- Segment orders by delivery speed
WITH delivery_segments AS (
    SELECT
        order_id,
        order_date,
        delivery_date,
        delivery_days,
        occasion,
        revenue,
        CASE
            WHEN delivery_days = 0 THEN 'Same Day'
            WHEN delivery_days BETWEEN 1 AND 3 THEN 'Fast (1-3 days)'
            WHEN delivery_days BETWEEN 4 AND 7 THEN 'Standard (4-7 days)'
            ELSE 'Slow (8+ days)'
        END AS delivery_segment
    FROM gold.fact_orders
)
SELECT
    delivery_segment,
    COUNT(order_id)             AS total_orders,
    ROUND(AVG(revenue), 2)      AS avg_order_value,
    SUM(revenue)                AS total_revenue
FROM delivery_segments
GROUP BY delivery_segment
ORDER BY total_orders DESC;