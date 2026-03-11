/*
=============================================================
Create Database and Schemas
=============================================================
This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/


USE master;
GO

-- Drop and recreate the 'Ferns_Petals_DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Ferns_Petals_DataWarehouse')
BEGIN
    ALTER DATABASE Ferns_Petals_DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Ferns_Petals_DataWarehouse;
END;
GO

--Create Database Fern & Petals 

CREATE DATABASE Ferns_Petals_DataWarehouse;
GO

USE Ferns_Petals_DataWarehouse;
GO


--Create Schema

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO