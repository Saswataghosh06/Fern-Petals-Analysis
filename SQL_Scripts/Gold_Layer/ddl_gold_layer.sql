/*
===============================================================================
DDL Script: Create Gold Tables
===============================================================================
Script Purpose:
    Creates tables in the gold schema — the final business-ready layer.
    Gold follows a Star Schema pattern:
    - Dimension tables: dim_customers, dim_products
    - Fact table: fact_orders

    Key additions over Silver:
    - Surrogate keys added to all tables using ROW_NUMBER()
    - Only business-relevant columns kept — no raw or intermediate columns
    - This is the only layer Power BI connects to

===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- -----------------------------------------------
-- gold.dim_customers
-- -----------------------------------------------
IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL
    DROP TABLE gold.dim_customers;
GO
CREATE TABLE gold.dim_customers (
    customer_key    INT,            -- surrogate key
    customer_id     NVARCHAR(50),   -- natural key from source
    name            NVARCHAR(255),
    city            NVARCHAR(100),
    gender          NVARCHAR(20)
);
GO

-- -----------------------------------------------
-- gold.dim_products
-- -----------------------------------------------
IF OBJECT_ID('gold.dim_products', 'U') IS NOT NULL
    DROP TABLE gold.dim_products;
GO
CREATE TABLE gold.dim_products (
    product_key     INT,            -- surrogate key
    product_id      NVARCHAR(50),   -- natural key from source
    product_name    NVARCHAR(255),
    category        NVARCHAR(100),
    price_inr       DECIMAL(10,2),
    occasion        NVARCHAR(100)
);
GO

-- -----------------------------------------------
-- gold.fact_orders
-- -----------------------------------------------
IF OBJECT_ID('gold.fact_orders', 'U') IS NOT NULL
    DROP TABLE gold.fact_orders;
GO
CREATE TABLE gold.fact_orders (
    order_key       INT,            -- surrogate key
    order_id        NVARCHAR(50),
    customer_key    INT,            -- FK to dim_customers
    product_key     INT,            -- FK to dim_products
    quantity        INT,
    order_date      DATE,
    order_time      TIME,
    delivery_date   DATE,
    delivery_days   INT,
    order_hour      INT,
    order_day       NVARCHAR(20),
    order_month     NVARCHAR(20),
    location        NVARCHAR(100),
    occasion        NVARCHAR(100),
    revenue         DECIMAL(10,2)
);
GO

--Verify Gold Layer
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_NAME, ORDINAL_POSITION;