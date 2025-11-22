import json, boto3, os, logging
from datetime import datetime

'''
curl -X POST https://api.aws-serverless.net/api-notify \
  -H "Content-Type: application/json" \
  -d '{"message": "Test notification from curl"}'
'''

# {
#   "status": "published",
#   "message_id": "1234abcd-...",
#   "message": "Test notification from curl"
# }

'''
curl -X GET https://api.aws-serverless.net/api-notify \
  -H "Content-Type: application/json"
'''

# {
#   "count": 1,
#   "subscriptions": [...]
# }

'''
curl -X PUT https://api.aws-serverless.net/api-notify \
  -H "Content-Type: application/json" \
  -d '{"protocol": "email", "endpoint": "your_email@example.com"}'
'''

# {
#   "status": "subscribed",
#   "subscription_arn": "pending confirmation"
# }

'''
curl -X DELETE https://api.aws-serverless.net/api-notify \
  -H "Content-Type: application/json" \
  -d '{"subscription_arn": "arn:aws:sns:us-east-1:272645820685:your-topic:abcd1234"}'
'''

# {
#   "status": "unsubscribed",
#   "subscription_arn": "arn:aws:sns:..."
# }

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client("sns")
TOPIC_ARN = os.environ["TOPIC_ARN"]

COMMON_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
}

def response(code, body):
    return {
        "statusCode": code,
        "headers": COMMON_HEADERS,
        "body": json.dumps(body)
    }

def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    logger.info(f"Incoming method: {method}")
    logger.info(f"Event: {json.dumps(event)}")

    # --- Handle preflight ---
    if method == "OPTIONS":
        return {"statusCode": 200, "headers": COMMON_HEADERS}

    body = {}
    if event.get("body"):
        try:
            body = json.loads(event["body"])
        except Exception:
            logger.warning("Invalid JSON body")

    try:
        match method:
            case "POST":
                message = body.get("message", "Hello from API-NOTIFY!")
                resp = sns.publish(TopicArn=TOPIC_ARN, Message=message)
                return response(200, {
                    "status": "published",
                    "message_id": resp.get("MessageId"),
                    "message": message
                })

            case "GET":
                subs = sns.list_subscriptions_by_topic(TopicArn=TOPIC_ARN).get("Subscriptions", [])
                return response(200, {"count": len(subs), "subscriptions": subs})

            case "PUT":
                protocol = body.get("protocol", "email")
                endpoint = body.get("endpoint")
                if not endpoint:
                    return response(400, {"error": "Missing 'endpoint'"})
                sub = sns.subscribe(TopicArn=TOPIC_ARN, Protocol=protocol, Endpoint=endpoint)
                arn = sub.get("SubscriptionArn", "PENDING_CONFIRMATION")
                return response(200, {"status": "subscribed", "subscription_arn": arn})

            case "DELETE":
                arn = body.get("subscription_arn")
                if not arn:
                    return response(400, {"error": "Missing 'subscription_arn'"})
                sns.unsubscribe(SubscriptionArn=arn)
                return response(200, {"status": "unsubscribed", "subscription_arn": arn})

            case _:
                return response(405, {"error": f"Method {method} not allowed"})

    except Exception as e:
        logger.exception("Unhandled exception")
        return response(500, {"error": str(e)})
