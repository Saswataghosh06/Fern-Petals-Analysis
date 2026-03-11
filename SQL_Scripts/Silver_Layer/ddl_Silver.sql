/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    Creates tables in the silver schema with proper data types.
    Replaces raw VARCHAR/auto-detected types from the bronze layer.

    Key changes from Bronze:
    - ID columns: int/tinyint → NVARCHAR (IDs are identifiers, not numbers)
    - Contact_Number: bigint → NVARCHAR (preserves leading zeros)
    - Price_INR: smallint → DECIMAL(10,2) (monetary precision)
    - Revenue: new derived column (Quantity x Price_INR)
    - Delivery_Days: new derived column (delivery_date - order_date)
    - Order_Hour: new derived column (hour from order_time)
    - Order_Day: new derived column (weekday name)
    - Order_Month: new derived column (month name)
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

-- -----------------------------------------------
-- silver.orders
-- -----------------------------------------------
IF OBJECT_ID('silver.orders', 'U') IS NOT NULL
    DROP TABLE silver.orders;
GO
CREATE TABLE silver.orders (
    order_id        NVARCHAR(50),
    customer_id     NVARCHAR(50),
    product_id      NVARCHAR(50),
    quantity        INT,
    order_date      DATE,
    order_time      TIME,
    delivery_date   DATE,
    delivery_time   TIME,
    delivery_days   INT,
    order_hour      INT,
    order_day       NVARCHAR(20),
    order_month     NVARCHAR(20),
    location        NVARCHAR(100),
    occasion        NVARCHAR(100),
    revenue         DECIMAL(10,2)
);
GO

-- -----------------------------------------------
-- silver.products
-- -----------------------------------------------
IF OBJECT_ID('silver.products', 'U') IS NOT NULL
    DROP TABLE silver.products;
GO
CREATE TABLE silver.products (
    product_id      NVARCHAR(50),
    product_name    NVARCHAR(255),
    category        NVARCHAR(100),
    price_inr       DECIMAL(10,2),
    occasion        NVARCHAR(100),
    description     NVARCHAR(500)
);
GO

-- -----------------------------------------------
-- silver.customers
-- -----------------------------------------------
IF OBJECT_ID('silver.customers', 'U') IS NOT NULL
    DROP TABLE silver.customers;
GO
CREATE TABLE silver.customers (
    customer_id     NVARCHAR(50),
    name            NVARCHAR(255),
    city            NVARCHAR(100),
    contact_number  NVARCHAR(20),
    email           NVARCHAR(255),
    gender          NVARCHAR(20),
    address         NVARCHAR(500)
);
GO


--Verify Silver Layer
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'silver'
ORDER BY TABLE_NAME, ORDINAL_POSITION;