-- ===== DIMENSION TABLES =====
-- 1. DimDate
CREATE TABLE dbo.DimDate (
    DateKey        INT        NOT NULL PRIMARY KEY,  
    FullDate       DATE       NOT NULL,
    [Year]         INT        NOT NULL,
    [Quarter]      INT        NOT NULL,
    [Month]        INT        NOT NULL,
    [Day]          INT        NOT NULL
);

-- 2. DimCustomer (SCD Type 2)
CREATE TABLE dbo.DimCustomer (
    CustomerKey    INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID     NVARCHAR(50) NOT NULL,   -- business key
    FullName       NVARCHAR(200) NULL,
    Segment        NVARCHAR(50)  NULL,
    EffectiveFrom  DATETIME2     NOT NULL,
    EffectiveTo    DATETIME2     NULL,
    IsCurrent      BIT           NOT NULL
);

-- 3. DimAccount
CREATE TABLE dbo.DimAccount (
    AccountKey     INT IDENTITY(1,1) PRIMARY KEY,
    AccountNumber  NVARCHAR(50) NOT NULL,
    CustomerID     NVARCHAR(50) NULL,
    AccountType    NVARCHAR(50) NULL,
    Status         NVARCHAR(20) NULL,
    OpenDate       DATE         NULL,
    CloseDate      DATE         NULL
);

-- 4. DimBranch (simple – optional)
CREATE TABLE dbo.DimBranch (
    BranchKey      INT IDENTITY(1,1) PRIMARY KEY,
    BranchCode     NVARCHAR(50) NOT NULL,
    BranchName     NVARCHAR(200) NULL,
    City           NVARCHAR(100) NULL,
    State          NVARCHAR(100) NULL
);

-- 5. DimProduct (simple – optional)
CREATE TABLE dbo.DimProduct (
    ProductKey     INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode    NVARCHAR(50) NOT NULL,   -- e.g., SAV, CURR, LOAN
    ProductName    NVARCHAR(100) NULL,
    ProductType    NVARCHAR(50) NULL        -- Savings / Current / Loan
);
-- ===== FACT TABLES =====

-- FactTransactions
CREATE TABLE dbo.FactTransactions (
    TransactionKey    BIGINT IDENTITY(1,1) PRIMARY KEY,
    TransactionID     NVARCHAR(50) NOT NULL,
    DateKey           INT          NOT NULL,
    CustomerID        NVARCHAR(50) NULL,    -- or FK to DimCustomer if you join later
    AccountNumber     NVARCHAR(50) NULL,    -- or FK to DimAccount
    Channel           NVARCHAR(10) NULL,    -- ATM / UPI
    TxnType           NVARCHAR(50) NULL,
    Amount            DECIMAL(18,2) NULL,
    [Status]          NVARCHAR(20) NULL,
    ATMID             NVARCHAR(50) NULL,
    PayerUPI          NVARCHAR(200) NULL,
    PayeeUPI          NVARCHAR(200) NULL,
    DeviceID          NVARCHAR(100) NULL,
    Location          NVARCHAR(200) NULL
);

-- FactFraudDetection  (from gold FactFraudDetection)
CREATE TABLE dbo.FactFraudDetection (
    FraudKey         BIGINT IDENTITY(1,1) PRIMARY KEY,
    AlertID          NVARCHAR(100) NOT NULL,
    AlertType        NVARCHAR(200) NOT NULL,
    TxnID            NVARCHAR(50)  NULL,
    TxnType          NVARCHAR(50)  NULL,
    Amount           DECIMAL(18,2) NULL,
    SourceFile       NVARCHAR(200) NULL,
    AlertDateKey     INT           NULL,    -- link to DimDate
    AlertTime        DATETIME2     NULL
);

-- FactCustomerActivity (you can fill later from logs or leave empty)
CREATE TABLE dbo.FactCustomerActivity (
    ActivityKey      BIGINT IDENTITY(1,1) PRIMARY KEY,
    CustomerID       NVARCHAR(50) NOT NULL,
    ActivityDateKey  INT          NOT NULL,
    Channel          NVARCHAR(20) NULL,  -- MOBILE / WEB / ATM / BRANCH
    ActivityType     NVARCHAR(50) NULL,  -- LOGIN / PASSWORD_RESET / etc.
    ActivityCount    INT          NULL
);

-- Implement MERGE / UPSERT for daily sync (SCD Type-2)
-- Create staging tables
CREATE TABLE dbo.StgCustomer (
    CustomerID  VARCHAR(50),
    FullName    VARCHAR(200)
);

CREATE TABLE dbo.StgAccount (
    AccountNumber VARCHAR(50),
    CustomerID    VARCHAR(50),
    Status        VARCHAR(50),
    AccountType   VARCHAR(50)
);

SELECT * FROM [dbo].[StgCustomer];

SELECT TOP 20 * FROM dbo.StgCustomer;

-- MERGE for DimCustomer (SCD Type-2)
MERGE dbo.DimAccount AS target
USING dbo.StgAccount AS source
ON target.AccountNumber = source.AccountNumber

WHEN MATCHED THEN
    UPDATE SET 
        target.CustomerID  = source.CustomerID,
        target.Status      = source.Status,
        target.AccountType = source.AccountType

WHEN NOT MATCHED THEN
    INSERT (AccountNumber, CustomerID, Status, AccountType)
    VALUES (source.AccountNumber, source.CustomerID, source.Status, source.AccountType);



