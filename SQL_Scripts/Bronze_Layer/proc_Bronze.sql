/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    Loads raw data from external CSV files into the bronze schema tables.
    Truncates each table before loading — full refresh pattern.
    Logs row counts and duration for every table and the full batch.

Parameters: None

Usage:
    EXEC bronze.load_bronze;

===============================================================================
ENVIRONMENT NOTE:
    This procedure uses BULK INSERT which requires the SQL Server service
    account to have READ access to the source file path.

    In SQL Server Express on a local machine, the service account
    (NT Service\MSSQL$SQLEXPRESS) does not have file system access by default.

    WORKAROUND USED IN THIS PROJECT:
    Data was loaded using the SSMS Import Flat File Wizard which runs under
    the Windows user account and bypasses service account restrictions.

    PRODUCTION FIX:
    Grant READ permission on the source folder to the SQL Server service account:
    Folder → Right-click → Properties → Security → Add → NT Service\MSSQL$SQLEXPRESS → Read
===============================================================================
*/

USE Ferns_Petals_DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
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
        PRINT 'Loading Bronze Layer';
        PRINT 'Batch Start: ' + CAST(@batch_start AS NVARCHAR);
        PRINT '==========================================';

        -- -----------------------------------------------
        -- Load: bronze.orders
        -- -----------------------------------------------
        PRINT '>> Truncating Table: bronze.orders';
        TRUNCATE TABLE bronze.orders;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: bronze.orders';
        BULK INSERT bronze.orders
        FROM 'D:\Ferns_Petals_Project\Raw_Datasets\orders.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\r\n',
            TABLOCK
        );
        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- -----------------------------------------------
        -- Load: bronze.products
        -- -----------------------------------------------
        PRINT '>> Truncating Table: bronze.products';
        TRUNCATE TABLE bronze.products;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: bronze.products';
        BULK INSERT bronze.products
        FROM 'D:\Ferns_Petals_Project\Raw_Datasets\products.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\r\n',
            TABLOCK
        );
        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- -----------------------------------------------
        -- Load: bronze.customers
        -- -----------------------------------------------
        PRINT '>> Truncating Table: bronze.customers';
        TRUNCATE TABLE bronze.customers;

        SET @start_time = GETDATE();
        PRINT '>> Inserting Data Into: bronze.customers';
        BULK INSERT bronze.customers
        FROM 'D:\Ferns_Petals_Project\Raw_Datasets\customers.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\r\n',
            TABLOCK
        );
        SET @end_time  = GETDATE();
        SET @row_count = @@ROWCOUNT;
        PRINT '>> Rows Inserted: ' + CAST(@row_count AS NVARCHAR);
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end = GETDATE();
        PRINT '==========================================';
        PRINT 'Bronze Layer Load Completed Successfully';
        PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start, @batch_end) AS NVARCHAR) + ' seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE()  AS NVARCHAR);
        PRINT '==========================================';
    END CATCH

END;
GO