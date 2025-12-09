import logging
import json
import datetime as dt
import azure.functions as func


def main(event: func.EventGridEvent,
         fraudAlertOut: func.Out[func.Document],
         serviceBusMsg: func.Out[str]) -> None:

    logging.info("FraudDetectionHandler triggered")

    data = event.get_json()
    amount = data.get("amount", 0)
    customer_id = data.get("customer_id")
    location = data.get("location")
    device_id = data.get("device_id")
    txn_time_str = data.get("txn_timestamp")

    try:
        txn_time = dt.datetime.fromisoformat(txn_time_str.replace("Z", ""))
    except Exception:
        txn_time = dt.datetime.utcnow()

    rules_triggered = []

    if txn_time.hour < 6 or txn_time.hour > 22:
        rules_triggered.append("Odd login/txn time")

    if amount >= 100000:
        rules_triggered.append("Very high amount")

    if location not in ["HYDERABAD", "VIJAYAWADA"]:
        rules_triggered.append("Unusual location")

    if not rules_triggered:
        logging.info("No anomaly detected for txn %s", data.get("transaction_id"))
        return

    alert_id = f"ALERT_{data.get('transaction_id')}"

    alert_doc = {
        "id": alert_id,
        "txn_id": data.get("transaction_id"),
        "customer_id": customer_id,
        "amount": amount,
        "location": location,
        "device_id": device_id,
        "alert_time": dt.datetime.utcnow().isoformat(),
        "rules": rules_triggered,
        "severity": "HIGH" if amount >= 100000 else "MEDIUM",
        "source": "RealTimeEngine"
    }

    fraudAlertOut.set(func.Document.from_dict(alert_doc))

    sb_msg = {
        "alert_id": alert_id,
        "customer_id": customer_id,
        "amount": amount,
        "location": location,
        "rules": rules_triggered
    }
    serviceBusMsg.set(json.dumps(sb_msg))

    logging.info("Fraud alert created and queued for notification")

