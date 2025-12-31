import json
import boto3
import os

s3 = boto3.client("s3")

RAW_BUCKET = os.environ.get("RAW_DATA_BUCKET")

def lambda_handler(event, context):
    response = s3.list_objects_v2(
        Bucket=RAW_BUCKET,
        Prefix="events/"
    )

    objects = response.get("Contents", [])

    total_events = len(objects)

    summary = {
        "total_events": total_events
    }

    s3.put_object(
        Bucket=RAW_BUCKET,
        Key="processed/summary.json",
        Body=json.dumps(summary),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "summary": summary
    }
