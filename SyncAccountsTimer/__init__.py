import datetime
import logging
import pyodbc
import os

import azure.functions as func

def main(timer: func.TimerRequest) -> None:
    logging.info("🚀 Starting Daily Account Sync Job...")

    try:
        conn_str = os.getenv("SQL_CONN_STR")
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()

        merge_query = """
        MERGE dbo.DimAccount AS target
        USING dbo.StgAccount AS source
        ON target.AccountNumber = source.AccountNumber

        WHEN MATCHED AND (
            target.Status <> source.Status OR
            target.AccountType <> source.AccountType
        ) THEN
            UPDATE SET
                target.Status = source.Status,
                target.AccountType = source.AccountType,
                target.is_active = 1

        WHEN NOT MATCHED THEN
            INSERT (AccountNumber, CustomerID, Status, AccountType, is_active)
            VALUES (source.AccountNumber, source.CustomerID, source.Status, source.AccountType, 1);
        """

        cursor.execute(merge_query)
        conn.commit()

        cursor.close()
        conn.close()

        logging.info("🎯 SUCCESS: DimAccount updated successfully!")

    except Exception as e:
        logging.error(f"❌ ERROR in Account Sync: {e}")

