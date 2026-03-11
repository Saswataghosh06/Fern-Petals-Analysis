/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - Consolidates all key product metrics and behaviors into a single view.
    - Powers the product analytics page in Power BI.

Highlights:
    1. Gathers core product fields — name, category, occasion, price.
    2. Segments products by revenue performance:
       High Performer, Mid Range, Low Performer.
    3. Segments products by price band:
       Budget, Mid Range, Premium, Luxury.
    4. Aggregates product level metrics:
       - total orders
       - total revenue
       - total quantity sold
       - total unique customers
       - lifespan in months (first to last order)
    5. Calculates KPIs:
       - recency (days since last sale)
       - average order revenue
       - average monthly revenue

Tables Used:
    - gold.fact_orders
    - gold.dim_products
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact and dimension tables
---------------------------------------------------------------------------*/
    SELECT
        f.order_id,
        f.order_date,
        f.customer_key,
        f.revenue,
        f.quantity,
        f.occasion                                          AS order_occasion,
        p.product_key,
        p.product_id,
        p.product_name,
        p.category,
        p.price_inr,
        p.occasion                                          AS product_occasion
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),

product_aggregation AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
    SELECT
        product_key,
        product_id,
        product_name,
        category,
        price_inr,
        product_occasion,
        COUNT(DISTINCT order_id)                            AS total_orders,
        COUNT(DISTINCT customer_key)                        AS total_customers,
        SUM(revenue)                                        AS total_revenue,
        SUM(quantity)                                       AS total_quantity,
        MIN(order_date)                                     AS first_sale_date,
        MAX(order_date)                                     AS last_sale_date,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date))   AS lifespan_months,
        ROUND(
            AVG(CAST(revenue AS FLOAT) /
            NULLIF(quantity, 0))
        , 2)                                                AS avg_selling_price
    FROM base_query
    GROUP BY
        product_key,
        product_id,
        product_name,
        category,
        price_inr,
        product_occasion
)

/*---------------------------------------------------------------------------
3) Final Query: Combines aggregations with segments and KPIs
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_id,
    product_name,
    category,
    price_inr,
    product_occasion,

    -- Revenue performance segment
    CASE
        WHEN total_revenue > 100000 THEN 'High Performer'
        WHEN total_revenue >= 50000 THEN 'Mid Range'
        ELSE 'Low Performer'
    END                                                     AS revenue_segment,

    -- Price band segment
    CASE
        WHEN price_inr < 500                    THEN 'Budget (Below ₹500)'
        WHEN price_inr BETWEEN 500  AND 1000    THEN 'Mid Range (₹500-₹1000)'
        WHEN price_inr BETWEEN 1001 AND 1500    THEN 'Premium (₹1001-₹1500)'
        ELSE 'Luxury (Above ₹1500)'
    END                                                     AS price_segment,

    first_sale_date,
    last_sale_date,
    lifespan_months,

    -- Recency: days since last sale
    DATEDIFF(DAY, last_sale_date, '2023-12-31')             AS recency_days,

    total_orders,
    total_customers,
    total_revenue,
    total_quantity,
    avg_selling_price,

    -- Average order revenue
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE ROUND(total_revenue / total_orders, 2)
    END                                                     AS avg_order_revenue,

    -- Average monthly revenue
    CASE
        WHEN lifespan_months = 0 THEN total_revenue
        ELSE ROUND(total_revenue / lifespan_months, 2)
    END                                                     AS avg_monthly_revenue

FROM product_aggregation;
GO

-- Preview the view
SELECT TOP 20 *
FROM gold.report_products
ORDER BY total_revenue DESC;

-- Revenue segment summary
SELECT
    revenue_segment,
    COUNT(product_key)                  AS total_products,
    SUM(total_revenue)                  AS total_revenue,
    ROUND(AVG(total_revenue), 2)        AS avg_revenue_per_product,
    ROUND(AVG(avg_order_revenue), 2)    AS avg_order_revenue,
    ROUND(AVG(CAST(price_inr AS FLOAT)), 2) AS avg_price
FROM gold.report_products
GROUP BY revenue_segment
ORDER BY total_revenue DESC;

-- Price segment summary
SELECT
    price_segment,
    COUNT(product_key)                  AS total_products,
    SUM(total_revenue)                  AS total_revenue,
    ROUND(AVG(total_revenue), 2)        AS avg_revenue_per_product,
    SUM(total_orders)                   AS total_orders
FROM gold.report_products
GROUP BY price_segment
ORDER BY total_revenue DESC;

-- Category performance summary from the view
SELECT
    category,
    COUNT(product_key)                  AS total_products,
    SUM(total_revenue)                  AS total_revenue,
    SUM(total_orders)                   AS total_orders,
    ROUND(AVG(avg_order_revenue), 2)    AS avg_order_revenue,
    ROUND(AVG(CAST(price_inr AS FLOAT)), 2) AS avg_price
FROM gold.report_products
GROUP BY category
ORDER BY total_revenue DESC;

-- Top 10 products by revenue from the view
SELECT TOP 10
    product_name,
    category,
    price_inr,
    price_segment,
    revenue_segment,
    total_orders,
    total_customers,
    total_revenue,
    avg_order_revenue,
    avg_monthly_revenue
FROM gold.report_products
ORDER BY total_revenue DESC;