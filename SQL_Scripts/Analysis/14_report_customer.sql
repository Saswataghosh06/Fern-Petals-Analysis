/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - Consolidates all key customer metrics and behaviors into a single view.
    - Powers the customer analytics page in Power BI.

Highlights:
    1. Gathers core customer fields — name, city, gender.
    2. Segments customers by order frequency:
       Loyal (15+), Regular (10-14), Occasional (5-9), One Time (below 5).
    3. Aggregates customer level metrics:
       - total orders
       - total revenue
       - total quantity purchased
       - total unique products ordered
       - lifespan in days (first to last order)
    4. Calculates KPIs:
       - recency (days since last order)
       - average order value
       - average monthly spend

Tables Used:
    - gold.fact_orders
    - gold.dim_customers
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact and dimension tables
---------------------------------------------------------------------------*/
    SELECT
        f.order_id,
        f.product_key,
        f.order_date,
        f.delivery_days,
        f.occasion,
        f.revenue,
        f.quantity,
        c.customer_key,
        c.customer_id,
        c.name,
        c.city,
        c.gender
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),

customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
    SELECT
        customer_key,
        customer_id,
        name,
        city,
        gender,
        COUNT(DISTINCT order_id)                            AS total_orders,
        SUM(revenue)                                        AS total_revenue,
        SUM(quantity)                                       AS total_quantity,
        COUNT(DISTINCT product_key)                         AS total_products,
        COUNT(DISTINCT occasion)                            AS total_occasions,
        ROUND(AVG(CAST(delivery_days AS FLOAT)), 2)         AS avg_delivery_days,
        MIN(order_date)                                     AS first_order_date,
        MAX(order_date)                                     AS last_order_date,
        DATEDIFF(DAY, MIN(order_date), MAX(order_date))     AS lifespan_days,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date))   AS lifespan_months
    FROM base_query
    GROUP BY
        customer_key,
        customer_id,
        name,
        city,
        gender
)

/*---------------------------------------------------------------------------
3) Final Query: Combines aggregations with segments and KPIs
---------------------------------------------------------------------------*/
SELECT
    customer_key,
    customer_id,
    name,
    city,
    gender,

    -- Customer frequency segment
    CASE
        WHEN total_orders >= 15                     THEN 'Loyal'
        WHEN total_orders BETWEEN 10 AND 14         THEN 'Regular'
        WHEN total_orders BETWEEN 5  AND 9          THEN 'Occasional'
        ELSE 'One Time'
    END                                             AS customer_segment,

    first_order_date,
    last_order_date,
    lifespan_days,
    lifespan_months,

    -- Recency: days since last order
    DATEDIFF(DAY, last_order_date, '2023-12-31')    AS recency_days,

    total_orders,
    total_revenue,
    total_quantity,
    total_products,
    total_occasions,
    avg_delivery_days,

    -- Average order value
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_revenue / total_orders, 2)
    END                                             AS avg_order_value,

    -- Average monthly spend
    CASE
        WHEN lifespan_months = 0 THEN total_revenue
        ELSE ROUND(total_revenue / lifespan_months, 2)
    END                                             AS avg_monthly_spend

FROM customer_aggregation;
GO

-- Preview the view
SELECT TOP 20 *
FROM gold.report_customers
ORDER BY total_revenue DESC;

-- Segment summary from the view
SELECT
    customer_segment,
    COUNT(customer_key)             AS total_customers,
    SUM(total_revenue)              AS total_revenue,
    ROUND(AVG(total_revenue), 2)    AS avg_revenue_per_customer,
    ROUND(AVG(avg_order_value), 2)  AS avg_order_value,
    ROUND(AVG(CAST(recency_days AS FLOAT)), 2) AS avg_recency_days
FROM gold.report_customers
GROUP BY customer_segment
ORDER BY total_revenue DESC;