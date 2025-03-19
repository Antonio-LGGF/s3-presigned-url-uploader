import json
import boto3
import os

s3 = boto3.client("s3")
BUCKET_NAME = os.environ["BUCKET_NAME"]

def lambda_handler(event, context):
    file_name = event["queryStringParameters"]["file_name"]

    # Generate a pre-signed URL with Content-Type
    url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": BUCKET_NAME,
            "Key": file_name,
            "ContentType": "application/octet-stream"
        },
        ExpiresIn=3600
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"url": url})
    }
