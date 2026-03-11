/*
===============================================================================
Performance Analysis (Month-over-Month)
===============================================================================
Purpose:
    - To measure monthly revenue performance against the previous month.
    - To identify growth and decline periods.
    - To benchmark each month against the yearly average.

SQL Functions Used:
    - LAG(): Accesses previous row values for MoM comparison.
    - AVG() OVER(): Computes yearly average for benchmarking.
    - CASE: Flags performance direction.

Tables Used:
    - gold.fact_orders
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- Month over Month revenue performance
WITH monthly_revenue AS (
    SELECT
        DATETRUNC(MONTH, order_date)                        AS order_month,
        FORMAT(order_date, 'yyyy-MMM')                      AS order_month_name,
        SUM(revenue)                                        AS total_revenue,
        COUNT(DISTINCT order_id)                            AS total_orders
    FROM gold.fact_orders
    WHERE order_date IS NOT NULL
    GROUP BY
        DATETRUNC(MONTH, order_date),
        FORMAT(order_date, 'yyyy-MMM')
),
mom_calc AS (
    SELECT
        order_month,
        order_month_name,
        total_revenue,
        total_orders,
        LAG(total_revenue) OVER (ORDER BY order_month)      AS prev_month_revenue,
        AVG(total_revenue) OVER ()                          AS yearly_avg_revenue
    FROM monthly_revenue
)
SELECT
    order_month_name,
    total_revenue,
    total_orders,
    prev_month_revenue,

    -- Absolute MoM change
    total_revenue - prev_month_revenue                      AS mom_change,

    -- MoM change percentage
    ROUND(
        (total_revenue - prev_month_revenue)
        / NULLIF(prev_month_revenue, 0) * 100
    , 2)                                                    AS mom_change_pct,

    -- Performance direction flag
    CASE
        WHEN total_revenue > prev_month_revenue THEN 'Increase'
        WHEN total_revenue < prev_month_revenue THEN 'Decrease'
        ELSE 'No Change'
    END                                                     AS mom_direction,

    ROUND(yearly_avg_revenue, 2)                            AS yearly_avg_revenue,

    -- Above or below yearly average
    CASE
        WHEN total_revenue > yearly_avg_revenue THEN 'Above Average'
        WHEN total_revenue < yearly_avg_revenue THEN 'Below Average'
        ELSE 'Average'
    END                                                     AS vs_yearly_avg

FROM mom_calc
ORDER BY order_month;

-- Month over Month orders performance
WITH monthly_orders AS (
    SELECT
        DATETRUNC(MONTH, order_date)                        AS order_month,
        FORMAT(order_date, 'yyyy-MMM')                      AS order_month_name,
        COUNT(DISTINCT order_id)                            AS total_orders
    FROM gold.fact_orders
    WHERE order_date IS NOT NULL
    GROUP BY
        DATETRUNC(MONTH, order_date),
        FORMAT(order_date, 'yyyy-MMM')
),
orders_lag AS (
    SELECT
        order_month,
        order_month_name,
        total_orders,
        LAG(total_orders) OVER (ORDER BY order_month)       AS prev_month_orders
    FROM monthly_orders
)
SELECT
    order_month_name,
    total_orders,
    prev_month_orders,
    total_orders - prev_month_orders                        AS mom_order_change,
    CASE
        WHEN total_orders > prev_month_orders THEN 'Increase'
        WHEN total_orders < prev_month_orders THEN 'Decrease'
        ELSE 'No Change'
    END                                                     AS mom_direction
FROM orders_lag
ORDER BY order_month;

-- Product level MoM performance
WITH monthly_product_revenue AS (
    SELECT
        FORMAT(f.order_date, 'yyyy-MMM')                    AS order_month,
        DATETRUNC(MONTH, f.order_date)                      AS order_month_sort,
        p.product_name,
        SUM(f.revenue)                                      AS total_revenue
    FROM gold.fact_orders f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY
        FORMAT(f.order_date, 'yyyy-MMM'),
        DATETRUNC(MONTH, f.order_date),
        p.product_name
),
product_lag AS (
    SELECT
        order_month,
        order_month_sort,
        product_name,
        total_revenue,
        AVG(total_revenue) OVER (
            PARTITION BY product_name
        )                                                   AS avg_monthly_revenue,
        LAG(total_revenue) OVER (
            PARTITION BY product_name
            ORDER BY order_month_sort
        )                                                   AS prev_month_revenue
    FROM monthly_product_revenue
)
SELECT
    order_month,
    product_name,
    total_revenue,
    ROUND(avg_monthly_revenue, 2)                           AS avg_monthly_revenue,
    total_revenue - avg_monthly_revenue                     AS diff_from_avg,
    CASE
        WHEN total_revenue > avg_monthly_revenue THEN 'Above Avg'
        WHEN total_revenue < avg_monthly_revenue THEN 'Below Avg'
        ELSE 'Avg'
    END                                                     AS performance_flag,
    prev_month_revenue,
    CASE
        WHEN total_revenue > prev_month_revenue THEN 'Increase'
        WHEN total_revenue < prev_month_revenue THEN 'Decrease'
        ELSE 'No Change'
    END                                                     AS mom_direction
FROM product_lag
ORDER BY product_name, order_month_sort;