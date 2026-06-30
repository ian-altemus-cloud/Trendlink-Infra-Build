import json
import random
import uuid
import boto3
import logging
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

eventbridge = boto3.client('events')

SOURCES = [
    "crm.salesforce",
    "payments.stripe",
    "banking.core",
    "kyc.jumio",
    "cards.marqeta"
]

def generate_records(count):
    records = []
    for _ in range(count):
        records.append({
            "record_id": str(uuid.uuid4()),
            "account_id": f"ACC-{random.randint(100000, 999999)}",
            "transaction_amount": round(random.uniform(1.00, 9999.99), 2),
            "currency": random.choice(["USD", "EUR", "GBP"]),
            "timestamp_raw": datetime.now(timezone.utc).strftime("%m/%d/%Y %H:%M:%S"),
            "status": "PENDING",
            "data_classification": "PII"
        })
    return records

def lambda_handler(event, context):
    job_id = str(uuid.uuid4())
    source_name = random.choice(SOURCES)
    record_count = random.randint(10, 50)
    timestamp = datetime.now(timezone.utc).isoformat()

    # 20% intentional failure rate
    should_fail = random.random() < 0.2

    if should_fail:
        logger.error(f"Job {job_id} failed at ingestion from {source_name}")
        raise Exception(f"Simulated ingestion failure for job {job_id} from {source_name}")

    records = generate_records(record_count)

    event_detail = {
        "job_id": job_id,
        "source_name": source_name,
        "record_count": record_count,
        "timestamp": timestamp,
        "status": "STARTED",
        "data_classification": "PII",
        "records": records
    }

    import os
    event_bus_name = os.environ["EVENT_BUS_NAME"]

    response = eventbridge.put_events(
        Entries=[
            {
                "Source": "pipeline.ingestion",
                "DetailType": "JobStarted",
                "Detail": json.dumps(event_detail),
                "EventBusName": event_bus_name
            }
        ]
    )

    if response["FailedEntryCount"] > 0:
        logger.error(f"EventBridge rejected event for job {job_id}")
        raise Exception(f"EventBridge put_events failed for job {job_id}")

    logger.info(f"Job {job_id} published to EventBridge — {record_count} records from {source_name}")

    return {
        "statusCode": 200,
        "job_id": job_id,
        "source_name": source_name,
        "record_count": record_count,
        "status": "STARTED"
    }