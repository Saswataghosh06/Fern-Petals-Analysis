/*
===============================================================================
Stored Procedure: Load Gold Layer (Silver -> Gold)
===============================================================================
Script Purpose:
    Transforms and loads data from silver schema into gold schema.

    Transformations Applied:

    gold.dim_customers:
    - Select distinct customers from silver
    - Add surrogate key using ROW_NUMBER()
    - Drop contact, email, address — not needed for analytics

    gold.dim_products:
    - Select distinct products from silver
    - Add surrogate key using ROW_NUMBER()
    - Drop description — not needed for analytics

    gold.fact_orders:
    - Join silver.orders to dim_customers and dim_products
    - Replace natural keys with surrogate keys
    - Add surrogate key for fact table itself
    - Keep all metrics: revenue, delivery_days, order_hour etc

Parameters: None

Usage:
    EXEC gold.load_gold;
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time   DATETIME;
    DECLARE @end_time     DATETIME;
    DECLARE @batch_start  DATETIME;
    DECLARE @batch_end    DATETIME;
    DECLARE @row_count    INT;

    BEGIN TRY

        SET @batch_start = GETDATE();
        PRINT '==========================================';
        PRINT 'Loading Gold Layer';
        PRINT 'Batch Start: ' + CAST(@batch_start AS NVARCHAR);
        PRINT '==========================================';

        -- -----------------------------------------------
        -- Load: gold.dim_customers
        -- -----------------------------------------------
        PRINT '>> Truncating Table: gold.dim_customers';
        TRUNCATE TABLE gold.dim_customers;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: gold.dim_customers';
        INSERT INTO gold.dim_customers (
            customer_key,
            customer_id,
            name,
            city,
            gender
        )
        SELECT
            ROW_NUMBER() OVER (ORDER BY customer_id)   AS customer_key,
            customer_id,
            name,
            city,
            gender
        FROM silver.customers;

        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- -----------------------------------------------
        -- Load: gold.dim_products
        -- -----------------------------------------------
        PRINT '>> Truncating Table: gold.dim_products';
        TRUNCATE TABLE gold.dim_products;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: gold.dim_products';
        INSERT INTO gold.dim_products (
            product_key,
            product_id,
            product_name,
            category,
            price_inr,
            occasion
        )
        SELECT
            ROW_NUMBER() OVER (ORDER BY product_id)    AS product_key,
            product_id,
            product_name,
            category,
            price_inr,
            occasion
        FROM silver.products;

        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- -----------------------------------------------
        -- Load: gold.fact_orders
        -- Loaded LAST — joins to both dimension tables
        -- -----------------------------------------------
        PRINT '>> Truncating Table: gold.fact_orders';
        TRUNCATE TABLE gold.fact_orders;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: gold.fact_orders';
        INSERT INTO gold.fact_orders (
            order_key,
            order_id,
            customer_key,
            product_key,
            quantity,
            order_date,
            order_time,
            delivery_date,
            delivery_days,
            order_hour,
            order_day,
            order_month,
            location,
            occasion,
            revenue
        )
        SELECT
            ROW_NUMBER() OVER (ORDER BY o.order_id)    AS order_key,
            o.order_id,
            c.customer_key,
            p.product_key,
            o.quantity,
            o.order_date,
            o.order_time,
            o.delivery_date,
            o.delivery_days,
            o.order_hour,
            o.order_day,
            o.order_month,
            o.location,
            o.occasion,
            o.revenue
        FROM silver.orders o
        LEFT JOIN gold.dim_customers c
            ON o.customer_id = c.customer_id
        LEFT JOIN gold.dim_products p
            ON o.product_id = p.product_id;

        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end = GETDATE();
        PRINT '==========================================';
        PRINT 'Gold Layer Load Completed Successfully';
        PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start, @batch_end) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING GOLD LAYER LOAD';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE()  AS NVARCHAR);
        PRINT '==========================================';
    END CATCH

END;
GO

-- Execute
EXEC gold.load_gold;
GO

-- Verify row counts
SELECT 'gold.dim_customers' AS table_name, COUNT(*) AS row_count FROM gold.dim_customers
UNION ALL
SELECT 'gold.dim_products'  AS table_name, COUNT(*) AS row_count FROM gold.dim_products
UNION ALL
SELECT 'gold.fact_orders'   AS table_name, COUNT(*) AS row_count FROM gold.fact_orders;

-- Spot check surrogate keys in dimensions
SELECT TOP 5 customer_key, customer_id, name, city, gender
FROM gold.dim_customers;

SELECT TOP 5 product_key, product_id, product_name, category, price_inr
FROM gold.dim_products;

-- Spot check fact table joins worked correctly
SELECT TOP 5
    f.order_key,
    f.order_id,
    f.customer_key,
    c.name,
    c.city,
    f.product_key,
    p.product_name,
    f.occasion,
    f.revenue,
    f.delivery_days
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products  p ON f.product_key  = p.product_key;