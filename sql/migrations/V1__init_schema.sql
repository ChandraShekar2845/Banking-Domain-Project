--------------------------------------------------
-- V1 - Initial schema for BankDWH
--------------------------------------------------

-- 1. Create schema (optional, if you want a separate schema)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dwh')
    EXEC('CREATE SCHEMA dwh');
GO

--------------------------------------------------
-- 2. Dimension tables
--------------------------------------------------

-- DimDate: standard date dimension
CREATE TABLE dwh.DimDate (
    DateKey         INT         NOT NULL PRIMARY KEY, -- e.g. 20251209
    FullDate        DATE        NOT NULL,
    DayNumber       TINYINT     NOT NULL,
    DayName         VARCHAR(10) NOT NULL,
    MonthNumber     TINYINT     NOT NULL,
    MonthName       VARCHAR(10) NOT NULL,
    QuarterNumber   TINYINT     NOT NULL,
    YearNumber      SMALLINT    NOT NULL
);
GO

-- DimCustomer: details about bank customers
CREATE TABLE dwh.DimCustomer (
    CustomerKey     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CustomerId      NVARCHAR(50) NOT NULL,      -- source system ID
    FullName        NVARCHAR(200) NOT NULL,
    Gender          NVARCHAR(20)  NULL,
    DOB             DATE          NULL,
    City            NVARCHAR(100) NULL,
    State           NVARCHAR(100) NULL,
    Country         NVARCHAR(100) NULL,
    IsActive        BIT           NOT NULL DEFAULT 1,
    EffectiveFrom   DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    EffectiveTo     DATETIME2     NULL
);
GO

-- DimAccount: bank accounts
CREATE TABLE dwh.DimAccount (
    AccountKey      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    AccountNumber   NVARCHAR(50) NOT NULL,
    AccountType     NVARCHAR(50) NOT NULL, -- Savings, Current, etc.
    OpenDate        DATE         NULL,
    CloseDate       DATE         NULL,
    BranchCode      NVARCHAR(50) NULL
);
GO

-- DimBranch: branch info
CREATE TABLE dwh.DimBranch (
    BranchKey       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    BranchCode      NVARCHAR(50) NOT NULL,
    BranchName      NVARCHAR(200) NOT NULL,
    City            NVARCHAR(100) NULL,
    State           NVARCHAR(100) NULL,
    Country         NVARCHAR(100) NULL
);
GO

--------------------------------------------------
-- 3. Fact table for transactions
--------------------------------------------------

CREATE TABLE dwh.FactTransaction (
    TransactionKey      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey             INT         NOT NULL,  -- FK to DimDate
    CustomerKey         INT         NOT NULL,  -- FK to DimCustomer
    AccountKey          INT         NOT NULL,  -- FK to DimAccount
    BranchKey           INT         NULL,      -- FK to DimBranch
    TransactionId       NVARCHAR(100) NOT NULL,
    TransactionType     NVARCHAR(50)  NOT NULL, -- Debit/Credit
    Amount              DECIMAL(18,2) NOT NULL,
    CurrencyCode        CHAR(3)       NOT NULL,
    Channel             NVARCHAR(50)  NULL,     -- ATM, Online, Branch
    CreatedAtUtc        DATETIME2     NOT NULL
);
GO

--------------------------------------------------
-- 4. Foreign keys
--------------------------------------------------

ALTER TABLE dwh.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimDate
    FOREIGN KEY (DateKey) REFERENCES dwh.DimDate(DateKey);

ALTER TABLE dwh.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimCustomer
    FOREIGN KEY (CustomerKey) REFERENCES dwh.DimCustomer(CustomerKey);

ALTER TABLE dwh.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimAccount
    FOREIGN KEY (AccountKey) REFERENCES dwh.DimAccount(AccountKey);

ALTER TABLE dwh.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimBranch
    FOREIGN KEY (BranchKey) REFERENCES dwh.DimBranch(BranchKey);
GO
