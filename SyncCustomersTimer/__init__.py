import datetime
import logging
import pyodbc
import os

import azure.functions as func


def main(timer: func.TimerRequest) -> None:
    logging.info("Starting Daily Customer Sync Job...")

    try:
        conn_str = os.getenv("SQL_CONN_STR")
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()

        merge_query = """
        MERGE dbo.DimCustomer AS target
        USING dbo.StgCustomer AS source
        ON target.CustomerID = source.CustomerID

        WHEN MATCHED AND target.FullName <> source.FullName THEN
            UPDATE SET
                target.IsActive = 0,
                target.EndDate = GETDATE()

        WHEN NOT MATCHED THEN
            INSERT (CustomerID, FullName, StartDate, EndDate, IsActive)
            VALUES (source.CustomerID, source.FullName, GETDATE(), NULL, 1);
        """

        cursor.execute(merge_query)
        conn.commit()

        cursor.close()
        conn.close()

        logging.info("SUCCESS: DimCustomer updated successfully!")

    except Exception as e:
        logging.error(f"ERROR in Customer Sync: {e}")

