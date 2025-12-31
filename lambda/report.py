import json
import boto3
import os
from datetime import date

s3 = boto3.client("s3")

RAW_BUCKET = os.environ.get("RAW_DATA_BUCKET")
REPORTS_BUCKET = os.environ.get("REPORTS_BUCKET")

def lambda_handler(event, context):
    response = s3.get_object(
        Bucket=RAW_BUCKET,
        Key="processed/summary.json"
    )

    summary = json.loads(response["Body"].read())

    today = date.today().isoformat()

    report_content = {
        "date": today,
        "total_events": summary.get("total_events", 0)
    }

    s3.put_object(
        Bucket=REPORTS_BUCKET,
        Key=f"reports/{today}.json",
        Body=json.dumps(report_content),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "report": report_content
    }
