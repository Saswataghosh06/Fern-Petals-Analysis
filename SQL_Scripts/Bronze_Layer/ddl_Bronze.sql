/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    Creates tables in the bronze schema. All columns stored as VARCHAR or
    NVARCHAR — no type casting or transformations at this layer.
    Bronze captures the raw source structure exactly as it arrives.

    Run this script to recreate bronze table structures from scratch.
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

IF OBJECT_ID('bronze.orders', 'U') IS NOT NULL
    DROP TABLE bronze.orders;
GO
CREATE TABLE bronze.orders (
    order_id        NVARCHAR(50),
    customer_id     NVARCHAR(50),
    product_id      NVARCHAR(50),
    quantity        NVARCHAR(10),
    order_date      NVARCHAR(30),
    order_time      NVARCHAR(30),
    delivery_date   NVARCHAR(30),
    delivery_time   NVARCHAR(30),
    location        NVARCHAR(100),
    occasion        NVARCHAR(100)
);
GO

IF OBJECT_ID('bronze.products', 'U') IS NOT NULL
    DROP TABLE bronze.products;
GO
CREATE TABLE bronze.products (
    product_id      NVARCHAR(50),
    product_name    NVARCHAR(255),
    category        NVARCHAR(100),
    price_inr       NVARCHAR(20),
    occasion        NVARCHAR(100),
    description     NVARCHAR(500)
);
GO

IF OBJECT_ID('bronze.customers', 'U') IS NOT NULL
    DROP TABLE bronze.customers;
GO
CREATE TABLE bronze.customers (
    customer_id     NVARCHAR(50),
    name            NVARCHAR(255),
    city            NVARCHAR(100),
    contact_number  NVARCHAR(20),
    email           NVARCHAR(255),
    gender          NVARCHAR(20),
    address         NVARCHAR(500)
);
GO



--Verify

SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bronze'
ORDER BY TABLE_NAME, ORDINAL_POSITION;