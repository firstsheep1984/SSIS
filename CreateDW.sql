-- CREATE A DATABASE
USE master
GO

IF EXISTS (SELECT *FROM sys.sysdatabases WHERE name = 'DemoDW')
BEGIN
	DROP DATABASE DemoDW
END
GO

CREATE DATABASE DemoDW
GO

-- CREATE DIMENSION TABLES
USE DemoDW
GO

CREATE TABLE DimProduct
(ProductKey int identity NOT NULL PRIMARY KEY NONCLUSTERED,
 ProductAltKey nvarchar(10) NOT NULL,
 ProductName nvarchar(50) NULL,
 ProductDescription nvarchar(100) NULL,
 ProductCategoryName nvarchar(50))
GO

 CREATE TABLE DimGeography
 (GeographyKey int identity NOT NULL PRIMARY KEY NONCLUSTERED,
  PostalCode nvarchar(15) NULL,
  City nvarchar(50) NULL,
  Region nvarchar(50) NULL,
  Country nvarchar(50) NULL)
GO

 CREATE TABLE DimCustomer
(CustomerKey int identity NOT NULL PRIMARY KEY NONCLUSTERED,
 CustomerAltKey nvarchar(10) NOT NULL,
 CustomerName nvarchar(50) NULL,
 CustomerEmail nvarchar(50) NULL,
 CustomerGeographyKey int NULL REFERENCES DimGeography(GeographyKey))
GO


 CREATE TABLE DimSalesperson
(SalespersonKey int identity NOT NULL PRIMARY KEY NONCLUSTERED,
 SalesPersonAltKey nvarchar(10) NOT NULL,
 SalespersonName nvarchar(50) NULL,
 StoreName nvarchar(50) NULL,
 StoreGeographyKey int NULL REFERENCES DimGeography(GeographyKey))

 CREATE TABLE DimDate -- Comformed Dimension
 (DateKey int NOT NULL PRIMARY KEY NONCLUSTERED,
  DateAltKey datetime NOT NULL,
  CalendarYear int NOT NULL,
  CalendarQuarter int NOT NULL,
  MonthOfYear int NOT NULL,
  [MonthName] nvarchar(15) NOT NULL,
  [DayOfMonth] int NOT NULL,
  [DayOfWeek] int NOT NULL,
  [DayName] nvarchar(15) NOT NULL,
  FiscalYear int NOT NULL,
  FiscalQuarter int NOT NULL)
GO
  -- CREATE A FACT TABLE
  CREATE TABLE FactSalesOrders
  (ProductKey int NOT NULL REFERENCES DimProduct(ProductKey),
   CustomerKey int NOT NULL REFERENCES DimCustomer(CustomerKey),
   SalespersonKey int NOT NULL REFERENCES DimSalesperson(SalespersonKey),
   OrderDateKey int NOT NULL REFERENCES DimDate(DateKey),
   OrderNo int NOT NULL,
   ItemNo int NOT NULL,
   Quantity int NOT NULL,
   SalesAmount money NOT NULL,
   Cost money NOT NULL
    CONSTRAINT [PK_ FactSalesOrder] PRIMARY KEY NONCLUSTERED
 (
	[ProductKey],[CustomerKey],[SalesPersonKey],[OrderDateKey],[OrderNo],[ItemNo]
 )
 )
GO

-- POPULATE THE TIME DIMENSION TABLE
DECLARE @StartDate datetime
DECLARE @EndDate datetime
SET @StartDate = '01/01/2000'
SET @EndDate = getdate() 
DECLARE @LoopDate datetime
SET @LoopDate = @StartDate
WHILE @LoopDate <= @EndDate
BEGIN
  INSERT INTO dbo.DimDate VALUES
	(
		CAST(CONVERT(VARCHAR(8), @LoopDate, 112) AS int) , -- date key
		@LoopDate, -- date alt key
		Year(@LoopDate), -- calendar year
		datepart(qq, @LoopDate), -- calendar quarter
		Month(@LoopDate), -- month number of year
		datename(mm, @LoopDate), -- month name
		Day(@LoopDate),  -- day number of month
		datepart(dw, @LoopDate), -- day number of week
		datename(dw, @LoopDate), -- day name of week
		CASE
			WHEN Month(@LoopDate) < 7 THEN Year(@LoopDate)
			ELSE Year(@Loopdate) + 1
		 END, -- Fiscal year (assuming fiscal year runs from Jul to June)
		 CASE
			WHEN Month(@LoopDate) IN (1, 2, 3) THEN 3
			WHEN Month(@LoopDate) IN (4, 5, 6) THEN 4
			WHEN Month(@LoopDate) IN (7, 8, 9) THEN 1
			WHEN Month(@LoopDate) IN (10, 11, 12) THEN 2
		 END -- fiscal quarter 
	)  		  
	SET @LoopDate = DateAdd(dd, 1, @LoopDate)
END
