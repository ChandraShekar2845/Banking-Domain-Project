-- Average monthly spend / savings, and current balance

IF OBJECT_ID('dbo.vCustomerTxnAgg') IS NOT NULL
    DROP VIEW dbo.vCustomerTxnAgg;
GO

CREATE VIEW dbo.vCustomerTxnAgg AS
WITH TxnBase AS (
    SELECT
        ft.CustomerID,
        dd.Year AS YearNumber,
        dd.Month AS MonthNumber,
        ft.Amount,
        ft.TxnType
    FROM dbo.FactTransactions ft
    JOIN dbo.DimDate dd
        ON ft.DateKey = dd.DateKey
),
MonthlyAgg AS (
    SELECT
        CustomerID,
        YearNumber,
        MonthNumber,
        SUM(CASE 
                WHEN TxnType IN ('WITHDRAWAL','UPI','CARD_SPEND') 
                    THEN Amount 
                ELSE 0 END) AS MonthlySpend,
        SUM(CASE 
                WHEN TxnType IN ('DEPOSIT','SALARY','REFUND') 
                    THEN Amount 
                ELSE 0 END) AS MonthlySavings
    FROM TxnBase
    GROUP BY CustomerID, YearNumber, MonthNumber
)
SELECT
    CustomerID,
    AVG(MonthlySpend) AS AvgMonthlySpend,
    AVG(MonthlySavings) AS AvgMonthlySavings,
    SUM(MonthlySavings - MonthlySpend) AS TotalCurrentBalance
FROM MonthlyAgg
GROUP BY CustomerID;
GO

SELECT TOP 10 * FROM dbo.vCustomerTxnAgg;

-- Product Holdings / Accounts
IF OBJECT_ID('dbo.vCustomerProductAgg') IS NOT NULL
    DROP VIEW dbo.vCustomerProductAgg;
GO

CREATE VIEW dbo.vCustomerProductAgg AS
SELECT
    sa.CustomerID,
    COUNT(*) AS TotalAccounts,
    SUM(CASE WHEN da.AccountType = 'Savings' THEN 1 ELSE 0 END) AS SavingsAccountsCount,
    SUM(CASE WHEN da.AccountType = 'Loan' THEN 1 ELSE 0 END) AS LoanAccountsCount
FROM dbo.DimAccount da
JOIN dbo.StgAccount sa
    ON da.AccountNumber = sa.AccountNumber
WHERE da.is_active = 1
GROUP BY sa.CustomerID;
GO

SELECT TOP 10 * FROM dbo.vCustomerProductAgg;

-- Fraud Metrics & Fraud Score
IF OBJECT_ID('dbo.vCustomerFraudAgg') IS NOT NULL
    DROP VIEW dbo.vCustomerFraudAgg;
GO

CREATE VIEW dbo.vCustomerFraudAgg AS
SELECT
    ft.CustomerID,
    SUM(ff.FraudCount) AS TotalFraudCases,
    SUM(ff.TotalFraudAmount) AS TotalFraudAmount,
    MIN(ff.FraudDate) AS FirstFraudDate,
    MAX(ff.FraudDate) AS LastFraudDate
FROM dbo.FactFraudDetection ff
JOIN dbo.FactTransactions ft
    ON ff.TransactionID = ft.TransactionID
GROUP BY ft.CustomerID;
GO

SELECT TOP 10 * FROM dbo.vCustomerFraudAgg;

-- Customer Activity / Device & Login
SELECT 
    b.CustomerID,

    MAX(d.FullDate) AS LastLoginDate,

    COUNT(*) AS TotalActivityCount,

    SUM(
        CASE WHEN b.ActivityType = 'LOGIN' THEN 1 ELSE 0 END
    ) AS TotalLogins,

    SUM(
        CASE WHEN b.ActivityType = 'FAILED_LOGIN' THEN 1 ELSE 0 END
    ) AS FailedLoginAttempts

FROM dbo.FactCustomerActivity b
LEFT JOIN dbo.DimDate d
    ON b.ActivityDateKey = d.DateKey
GROUP BY b.CustomerID
ORDER BY TotalLogins DESC;

SELECT *
FROM dbo.FactCustomerActivity;

-- Final Customer360 View
CREATE dbo.vCustomer360 AS
SELECT  
    c.CustomerID,
    c.customer_name AS FullName,
    c.StartDate AS CustomerStartDate,
    c.EndDate AS CustomerEndDate,
    c.IsActive AS IsActiveCustomer,

    COALESCE(pa.NumberOfProducts, 0) AS TotalProducts,

    COALESCE(fa.FraudEventsCount, 0) AS FraudEventsCount,
    COALESCE(fa.FraudScore, 0) AS FraudScore,
    COALESCE(fa.TotalFraudLoss, 0) AS TotalFraudLoss,

    COALESCE(act.LastLoginDate, NULL) AS LastLoginDate,
    COALESCE(act.LoginCountLast30Days, 0) AS LoginCountLast30Days

FROM dbo.DimCustomer c
LEFT JOIN dbo.vCustomerProductAgg pa
    ON pa.CustomerID = c.CustomerID
LEFT JOIN dbo.vCustomerFraudAgg fa
    ON fa.CustomerID = c.CustomerID
LEFT JOIN dbo.vCustomerActivityAgg act
    ON act.CustomerID = c.CustomerID;


SELECT TOP 50 * FROM dbo.vCustomer360;

