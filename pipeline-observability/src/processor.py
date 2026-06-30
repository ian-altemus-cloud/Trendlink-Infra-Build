import json
import os
import uuid
import boto3
import logging
import urllib.request
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')


DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
PUSHGATEWAY_URL = os.environ['PUSHGATEWAY_URL']
ENVIRONMENT = os.environ['ENVIRONMENT']

table = dynamodb.Table(DYNAMODB_TABLE)

def clean_record(record):
    cleaned = record.copy()

    # Reformat timestamp to ISO 8601
    raw_ts = cleaned.get('timestamp_raw', '')
    try:
        dt = datetime.strptime(raw_ts, "%m/%d/%Y %H:%M:%S")
        cleaned['timestamp_iso'] = dt.replace(tzinfo=timezone.utc).isoformat()
    except ValueError:
        cleaned['timestamp_iso'] = datetime.now(timezone.utc).isoformat()

    # Clean account_id — strip prefix, zero pad to 8 digits
    account_id = cleaned.get('account_id', '')
    if account_id.startswith('ACC-'):
        numeric = account_id.replace('ACC-', '')
        cleaned['account_id_normalized'] = numeric.zfill(8)

    # Normalize currency to uppercase
    cleaned['currency'] = cleaned.get('currency', 'USD').upper()

    # Remove raw timestamp — replaced by ISO version
    cleaned.pop('timestamp_raw', None)

    return cleaned

def push_metrics(job_id, source_name, record_count, duration_ms, status):
    job_label = status.lower()
    source_label = source_name.replace('.', '_')

    metrics = f"""# HELP pipeline_jobs_total Total pipeline jobs processed
# TYPE pipeline_jobs_total counter
pipeline_jobs_total{{environment="{ENVIRONMENT}",source="{source_label}",status="{job_label}"}} 1
# HELP pipeline_records_total Total records processed
# TYPE pipeline_records_total counter
pipeline_records_total{{environment="{ENVIRONMENT}",source="{source_label}"}} {record_count}
# HELP pipeline_processing_duration_ms Processing duration in milliseconds
# TYPE pipeline_processing_duration_ms gauge
pipeline_processing_duration_ms{{environment="{ENVIRONMENT}",source="{source_label}"}} {duration_ms}
"""

    url = f"{PUSHGATEWAY_URL}/metrics/job/pipeline_observability/instance/{source_label}"

    try:
        data = metrics.encode('utf-8')
        req = urllib.request.Request(
            url,
            data=data,
            method='POST',
            headers={'Content-Type': 'text/plain'}
        )
        with urllib.request.urlopen(req, timeout=5) as response:
            logger.info(f"Pushed metrics to Pushgateway — status {response.status}")
    except Exception as e:
        logger.warning(f"Failed to push metrics to Pushgateway: {e}")


def publish_failure_alert(job_id, source_name, error):
    message = {
        "alert": "PIPELINE_JOB_FAILED",
        "job_id": job_id,
        "source_name": source_name,
        "error": str(error),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "environment": ENVIRONMENT,
        "compliance_note": "Failed PII job requires investigation per data handling policy"
    }

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"[ALERT] Pipeline job failed — {source_name}",
        Message=json.dumps(message, indent=2)
    )

def lambda_handler(event, context):
    for sqs_record in event['Records']:
        body = json.loads(sqs_record['body'])

        # EventBridge wraps the payload in a detail key
        detail = body.get('detail', body)

        job_id = detail.get('job_id', str(uuid.uuid4()))
        source_name = detail.get('source_name', 'unknown')
        record_count = detail.get('record_count', 0)
        records = detail.get('records', [])

        start_time = datetime.now(timezone.utc)
        status = 'COMPLETE'
        error_detail = None
        processed_count = 0

        try:
            for record in records:
                clean_record(record)
                processed_count += 1

            duration_ms = int(
                (datetime.now(timezone.utc) - start_time)
                .total_seconds() * 1000
            )

            table.put_item(
                Item={
                    'job_id': job_id,
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'source_name': source_name,
                    'record_count': record_count,
                    'processed_count': processed_count,
                    'status': status,
                    'processing_duration_ms': duration_ms,
                    'data_classification': detail.get('data_classification', 'PII'),
                    'environment': ENVIRONMENT
                }
            )

            logger.info(f"Job {job_id} complete — {processed_count} records from {source_name} in {duration_ms}ms")

        except Exception as e:
            status = 'FAILED'
            error_detail = str(e)
            duration_ms = int(
                (datetime.now(timezone.utc) - start_time)
                .total_seconds() * 1000
            )

            logger.error(f"Job {job_id} failed — {error_detail}")

            table.put_item(
                Item={
                    'job_id': job_id,
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'source_name': source_name,
                    'record_count': record_count,
                    'processed_count': processed_count,
                    'status': status,
                    'error_detail': error_detail,
                    'processing_duration_ms': duration_ms,
                    'data_classification': detail.get('data_classification', 'PII'),
                    'environment': ENVIRONMENT
                }
            )

            publish_failure_alert(job_id, source_name, e)

        finally:
            push_metrics(job_id, source_name, processed_count, duration_ms, status)

    return {'statusCode': 200, 'processed': len(event['Records'])}