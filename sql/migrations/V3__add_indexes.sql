--------------------------------------------------
-- V3 - Add indexes for performance
--------------------------------------------------

-- 1. Indexes on FactTransaction
CREATE NONCLUSTERED INDEX IX_FactTransaction_Date_Customer
ON dwh.FactTransaction (DateKey, CustomerKey);

CREATE NONCLUSTERED INDEX IX_FactTransaction_Account
ON dwh.FactTransaction (AccountKey);

CREATE NONCLUSTERED INDEX IX_FactTransaction_Amount
ON dwh.FactTransaction (Amount);
GO

-- 2. Indexes on FactCustomerActivity
CREATE NONCLUSTERED INDEX IX_FactCustomerActivity_Date_Customer
ON dwh.FactCustomerActivity (DateKey, CustomerKey);

CREATE NONCLUSTERED INDEX IX_FactCustomerActivity_ActivityType
ON dwh.FactCustomerActivity (ActivityType);
GO

-- 3. Index on DimCustomer for fast lookup by source ID
CREATE NONCLUSTERED INDEX IX_DimCustomer_CustomerId
ON dwh.DimCustomer (CustomerId);
GO
