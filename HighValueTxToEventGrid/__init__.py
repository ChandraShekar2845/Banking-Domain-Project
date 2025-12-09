import logging
import json
import azure.functions as func

def main(event: func.EventGridEvent):
    logging.info(f"Received event subject: {event.subject}")
    logging.info(f"Event data: {event.get_json()}")

    events = []

    for doc in inputDocs:                                                                                                                                 # type: ignore
        txn = doc.to_dict()
        amount = txn.get("amount", 0)

        if amount >= 50000:
            event = {
                "id": txn.get("transaction_id"),
                "subject": f"/transactions/{txn.get('transaction_id')}",
                "eventType": "HighValueTransaction",
                "eventTime": txn.get("txn_timestamp"),
                "data": txn,
                "dataVersion": "1.0"
            }
            events.append(event)

    if events:
        logging.info(f"Publishing {len(events)} high-value txns to Event Grid")
        outputEvent.set(json.dumps(events))                                                                                                      # type: ignore

