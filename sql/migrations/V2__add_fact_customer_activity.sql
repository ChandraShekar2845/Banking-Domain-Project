--------------------------------------------------
-- V2 - Add FactCustomerActivity table
--------------------------------------------------

CREATE TABLE dwh.FactCustomerActivity (
    ActivityKey         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DateKey             INT         NOT NULL, -- FK to DimDate
    CustomerKey         INT         NOT NULL, -- FK to DimCustomer
    Channel             NVARCHAR(50) NOT NULL,   -- Mobile, Web, Branch
    ActivityType        NVARCHAR(100) NOT NULL,  -- Login, FailedLogin, PasswordChange
    ActivityCount       INT          NOT NULL DEFAULT 1,
    DeviceType          NVARCHAR(100) NULL,
    LocationCity        NVARCHAR(100) NULL,
    ActivityAtUtc       DATETIME2    NOT NULL
);
GO

-- Foreign keys
ALTER TABLE dwh.FactCustomerActivity
ADD CONSTRAINT FK_FactCustomerActivity_DimDate
    FOREIGN KEY (DateKey) REFERENCES dwh.DimDate(DateKey);

ALTER TABLE dwh.FactCustomerActivity
ADD CONSTRAINT FK_FactCustomerActivity_DimCustomer
    FOREIGN KEY (CustomerKey) REFERENCES dwh.DimCustomer(CustomerKey);
GO
