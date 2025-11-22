import os
import json
import boto3
import logging

'''
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Lambda SQS demo"}' \
  "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-queue"
'''

'''
curl -s -X GET \
  "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-queue"
'''

'''curl -s -X DELETE \
  -H "Content-Type: application/json" \
  -d '{"receiptHandle": "PASTE_RECEIPT_HANDLE_HERE"}' \
  "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-queue"
'''

'''curl -s -X PUT \
  -H "Content-Type: application/json" \
  -d '{"receiptHandle": "PASTE_RECEIPT_HANDLE_HERE", "visibilityTimeout": 10}' \
  "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-queue"
'''

# --- Logging setup ---
logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs = boto3.client("sqs")
QUEUE_URL = os.environ.get("QUEUE_URL")

def lambda_handler(event, context):
    logger.info(f"Event received: {json.dumps(event)}")

    method = event["requestContext"]["http"]["method"]
    body_raw = event.get("body")
    body = json.loads(body_raw) if body_raw else {}

    logger.info(f"HTTP Method: {method}")
    logger.info(f"Request body: {body}")

    try:
        if method == "POST":
            # --- Create / Send Message ---
            message = body.get("message", "no message")
            logger.info(f"Sending message: {message}")
            resp = sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=message)
            logger.info(f"Message sent with ID: {resp['MessageId']}")
            return _resp(200, {"messageId": resp["MessageId"]})

        elif method == "GET":
            # --- Read / Receive Message ---
            logger.info("Receiving message(s) from queue")
            resp = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                VisibilityTimeout=20,
                WaitTimeSeconds=0
            )
            messages = resp.get("Messages", [])
            logger.info(f"Received {len(messages)} message(s)")
            return _resp(200, messages)

        elif method == "DELETE":
            # --- Delete Message ---
            handle = body.get("receiptHandle")
            if not handle:
                logger.warning("DELETE called without receiptHandle")
                return _resp(400, {"error": "receiptHandle required"})
            logger.info(f"Deleting message with handle: {handle[:20]}...")
            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=handle)
            logger.info("Message deleted successfully")
            return _resp(200, {"deleted": True})

        elif method == "PUT":
            # --- Update Visibility Timeout ---
            handle = body.get("receiptHandle")
            timeout = int(body.get("visibilityTimeout", 30))
            if not handle:
                logger.warning("PUT called without receiptHandle")
                return _resp(400, {"error": "receiptHandle required"})
            logger.info(f"Updating visibility timeout to {timeout}s for handle: {handle[:20]}...")
            sqs.change_message_visibility(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=handle,
                VisibilityTimeout=timeout
            )
            logger.info("Visibility timeout updated successfully")
            return _resp(200, {"updated": True})

        else:
            logger.warning(f"Unsupported HTTP method: {method}")
            return _resp(405, {"error": f"method {method} not allowed"})

    except Exception as e:
        logger.exception("Error processing request")
        return _resp(500, {"error": str(e)})

def _resp(code, body):
    """Helper to format API Gateway responses."""
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }
