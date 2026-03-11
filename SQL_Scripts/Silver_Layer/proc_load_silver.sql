/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    Transforms and loads data from bronze schema into silver schema.

    Transformations applied:

    silver.products:
    - CAST Product_ID to NVARCHAR
    - CAST Price_INR to DECIMAL(10,2)
    - TRIM whitespace from all text columns
    - UPPER on Occasion for standardization
    - FILTER: remove records where Price_INR <= 0

    silver.customers:
    - CAST Customer_ID to NVARCHAR
    - CAST Contact_Number to NVARCHAR
    - TRIM whitespace from Name, City
    - STANDARDIZE Gender to Male/Female/Unknown
    - FILTER: remove records where Customer_ID is NULL

    silver.orders:
    - CAST all ID columns to NVARCHAR
    - CAST Quantity to INT
    - CAST dates to DATE, times to TIME
    - DERIVE Delivery_Days = DATEDIFF(day, order_date, delivery_date)
    - DERIVE Order_Hour = DATEPART(hour, order_time)
    - DERIVE Order_Day = DATENAME(weekday, order_date)
    - DERIVE Order_Month = DATENAME(month, order_date)
    - DERIVE Revenue = Quantity x Price_INR (joined from silver.products)
    - FILTER: remove records where delivery_date < order_date

Parameters: None

Usage:
    EXEC silver.load_silver;
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
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
        PRINT 'Loading Silver Layer';
        PRINT 'Batch Start: ' + CAST(@batch_start AS NVARCHAR);
        PRINT '==========================================';

        -- -----------------------------------------------
        -- Load: silver.products
        -- Load products FIRST — orders joins to this table
        -- -----------------------------------------------
        PRINT '>> Truncating Table: silver.products';
        TRUNCATE TABLE silver.products;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: silver.products';
        INSERT INTO silver.products (
            product_id,
            product_name,
            category,
            price_inr,
            occasion,
            description
        )
        SELECT
            CAST(Product_ID  AS NVARCHAR(50))      AS product_id,
            TRIM(Product_Name)                     AS product_name,
            TRIM(Category)                         AS category,
            CAST(Price_INR   AS DECIMAL(10,2))     AS price_inr,
            TRIM(UPPER(Occasion))                  AS occasion,
            TRIM(ISNULL(Description, ''))          AS description
        FROM bronze.products
        WHERE Price_INR IS NOT NULL
          AND TRY_CAST(Price_INR AS DECIMAL(10,2)) > 0;

        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- -----------------------------------------------
        -- Load: silver.customers
        -- -----------------------------------------------
        PRINT '>> Truncating Table: silver.customers';
        TRUNCATE TABLE silver.customers;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: silver.customers';
        INSERT INTO silver.customers (
            customer_id,
            name,
            city,
            contact_number,
            email,
            gender,
            address
        )
        SELECT
            CAST(Customer_ID    AS NVARCHAR(50))   AS customer_id,
            TRIM(Name)                             AS name,
            TRIM(City)                             AS city,
            CAST(Contact_Number AS NVARCHAR(20))   AS contact_number,
            TRIM(ISNULL(Email, ''))                AS email,
            CASE
                WHEN UPPER(TRIM(Gender)) IN ('M', 'MALE')   THEN 'Male'
                WHEN UPPER(TRIM(Gender)) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'Unknown'
            END                                    AS gender,
            TRIM(ISNULL(Address, ''))              AS address
        FROM bronze.customers
        WHERE Customer_ID IS NOT NULL;

        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- -----------------------------------------------
        -- Load: silver.orders
        -- Loaded LAST — joins to silver.products for Revenue
        -- -----------------------------------------------
        PRINT '>> Truncating Table: silver.orders';
        TRUNCATE TABLE silver.orders;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: silver.orders';
        INSERT INTO silver.orders (
            order_id,
            customer_id,
            product_id,
            quantity,
            order_date,
            order_time,
            delivery_date,
            delivery_time,
            delivery_days,
            order_hour,
            order_day,
            order_month,
            location,
            occasion,
            revenue
        )
        SELECT
            CAST(o.Order_ID      AS NVARCHAR(50))      AS order_id,
            CAST(o.Customer_ID   AS NVARCHAR(50))      AS customer_id,
            CAST(o.Product_ID    AS NVARCHAR(50))      AS product_id,
            CAST(o.Quantity      AS INT)               AS quantity,
            CAST(o.Order_Date    AS DATE)              AS order_date,
            CAST(o.Order_Time    AS TIME)              AS order_time,
            CAST(o.Delivery_Date AS DATE)              AS delivery_date,
            CAST(o.Delivery_Time AS TIME)              AS delivery_time,

            DATEDIFF(DAY,
                CAST(o.Order_Date    AS DATE),
                CAST(o.Delivery_Date AS DATE))         AS delivery_days,

            DATEPART(HOUR,
                CAST(o.Order_Time AS TIME))            AS order_hour,

            DATENAME(WEEKDAY,
                CAST(o.Order_Date AS DATE))            AS order_day,

            DATENAME(MONTH,
                CAST(o.Order_Date AS DATE))            AS order_month,

            TRIM(o.Location)                           AS location,
            TRIM(UPPER(o.Occasion))                    AS occasion,

            CAST(o.Quantity AS INT) * p.price_inr      AS revenue

        FROM bronze.orders o
        LEFT JOIN silver.products p
            ON CAST(o.Product_ID AS NVARCHAR(50)) = p.product_id

        WHERE o.Order_ID IS NOT NULL
          AND CAST(o.Delivery_Date AS DATE) >= CAST(o.Order_Date AS DATE);

        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end = GETDATE();
        PRINT '==========================================';
        PRINT 'Silver Layer Load Completed Successfully';
        PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start, @batch_end) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE()  AS NVARCHAR);
        PRINT '==========================================';
    END CATCH

END;
GO

-- Execute
EXEC silver.load_silver;
GO

-- Verify row counts
SELECT 'silver.orders'    AS table_name, COUNT(*) AS row_count FROM silver.orders
UNION ALL
SELECT 'silver.products'  AS table_name, COUNT(*) AS row_count FROM silver.products
UNION ALL
SELECT 'silver.customers' AS table_name, COUNT(*) AS row_count FROM silver.customers;

-- Spot check derived columns in orders
SELECT TOP 5
    order_id,
    order_date,
    delivery_date,
    delivery_days,
    order_hour,
    order_day,
    order_month,
    revenue
FROM silver.orders;

-- Spot check gender standardization in customers
SELECT DISTINCT gender FROM silver.customers;

-- Spot check price casting in products
SELECT TOP 5
    product_id,
    product_name,
    price_inr
FROM silver.products;
