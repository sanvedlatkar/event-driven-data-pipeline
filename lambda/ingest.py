import json
import boto3
from datetime import datetime
import os

s3 = boto3.client("s3")

RAW_BUCKET = os.environ.get("RAW_DATA_BUCKET")

def lambda_handler(event, context):
    timestamp = datetime.utcnow().isoformat()

    payload = {
        "timestamp": timestamp,
        "event": event
    }

    s3.put_object(
        Bucket=RAW_BUCKET,
        Key=f"events/{timestamp}.json",
        Body=json.dumps(payload),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "message": "Event stored successfully"
    }
