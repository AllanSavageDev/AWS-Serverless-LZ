import json
import boto3
import os
import logging
from datetime import datetime, timedelta
from decimal import Decimal

'''
curl -X POST https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-todo \
  -H "Content-Type: application/json" \
  -d '{"task": "buy milk", "ttl_seconds": 600}'

{"item":{"id":"20251026213045","task":"buy milk","created_at":"2025-10-26T21:30:45Z","ttl":1735309845,"done":false}}
✅ Expected →
Returns a 201 with an item object:
'''

'''
curl https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-todo

✅ Returns a list of all tasks.
curl "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-todo?id=20251027221251"
'''

'''
curl -X PUT https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-todo \
  -H "Content-Type: application/json" \
  -d '{"id":"20251026234158","task":"buy milk and eggs","done":true}'

✅ Returns {"message":"Updated"}
'''

'''
curl -X DELETE "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-todo?id=20251027221251"
✅ Returns {"message":"Deleted"}
'''

# --- Logging setup ---
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# TABLE_NAME = os.environ.get("TODO_TABLE", "t5-test-todo")
TABLE_NAME = "t5-test-todo"
logger.info(f"Using DynamoDB table: {TABLE_NAME}")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

def decimal_to_float(obj):
    if isinstance(obj, list):
        return [decimal_to_float(i) for i in obj]
    if isinstance(obj, dict):
        return {k: decimal_to_float(v) for k, v in obj.items()}
    if isinstance(obj, Decimal):
        return float(obj)
    return obj

def lambda_handler(event, context):
    logger.info(f"Incoming event: {json.dumps(event)}")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    logger.info(f"HTTP method detected: {method}")

    response = {"statusCode": 400, "headers": {"Content-Type": "application/json"}}


    path_params = event.get("pathParameters") or {}
    query_params = event.get("queryStringParameters") or {}
    path_id = path_params.get("id") or query_params.get("id")


    try:
        match method:
            # --- CREATE ---
            case "POST":
                logger.info("Handling POST request")
                body = json.loads(event.get("body") or "{}")
                logger.info(f"Parsed body: {body}")

                item_id = body.get("id") or datetime.utcnow().strftime("%Y%m%d%H%M%S")
                ttl_seconds = body.get("ttl_seconds", 3600)
                ttl_epoch = int((datetime.utcnow() + timedelta(seconds=ttl_seconds)).timestamp())

                item = {
                    "id": item_id,
                    "task": body.get("task", "no description"),
                    "created_at": datetime.utcnow().isoformat() + "Z",
                    "ttl": ttl_epoch,
                    "done": False,
                }
                logger.info(f"Putting item into DynamoDB: {item}")
                table.put_item(Item=item)
                response.update({"statusCode": 201, "body": json.dumps({"item": item})})

            # --- READ ---
            case "GET":
                logger.info("Handling GET request")
                params = event.get("queryStringParameters") or {}
                logger.info(f"Query parameters: {params}")
                item_id = params.get("id") if params else None

                if item_id:
                    logger.info(f"Fetching item by id: {item_id}")
                    res = table.get_item(Key={"id": item_id})
                    logger.info(f"DynamoDB get_item response: {res}")
                    item = res.get("Item")
                    if not item:
                        response.update({"statusCode": 404, "body": json.dumps({"error": "Not found"})})
                    else:
                        response.update({"statusCode": 200, "body": json.dumps(decimal_to_float(item))})
                else:
                    logger.info("Scanning table for all items")
                    res = table.scan()
                    logger.info(f"Scan returned {len(res.get('Items', []))} items")
                    response.update({"statusCode": 200, "body": json.dumps(decimal_to_float(res["Items"]))})
            # --- UPDATE ---
            case "PUT":
                logger.info("Handling PUT request")
                body = json.loads(event.get("body") or "{}")
                logger.info(f"Parsed body: {body}")
                item_id = path_id or body.get("id")
                if not item_id:
                    logger.warning("Missing id in PUT request")
                    response.update({"body": json.dumps({"error": "Missing id"})})
                else:
                    logger.info(f"Updating item id={item_id}")
                    table.update_item(
                        Key={"id": item_id},
                        UpdateExpression="SET task=:t, done=:d",
                        ExpressionAttributeValues={
                            ":t": body.get("task", "no description"),
                            ":d": body.get("done", False),
                        },
                    )
                    response.update({"statusCode": 200, "body": json.dumps({"message": "Updated"})})

            # --- DELETE ---
            case "DELETE":
                logger.info("Handling DELETE request")
                item_id = path_id
                logger.info(f"Item id to delete: {item_id}")

                logger.info(f"DELETE path_id={path_id}, key type={type(path_id)}")

                logger.info(f"Deleting from table: {TABLE_NAME}")


                if not item_id:
                    logger.warning("Missing id in DELETE request")
                    response.update({"body": json.dumps({"error": "Missing id"})})
                else:
                    table.delete_item(Key={"id": item_id})
                    response.update({"statusCode": 200, "body": json.dumps({"message": "Deleted"})})

            # --- DEFAULT ---
            case _:
                logger.warning(f"Unsupported HTTP method: {method}")
                response.update({
                    "statusCode": 405,
                    "body": json.dumps({"error": f"Method {method} not allowed"})
                })

    except Exception as e:
        logger.exception("Unhandled exception during Lambda execution")
        response.update({"statusCode": 500, "body": json.dumps({"error": str(e)})})

    logger.info(f"Response: {response}")
    return response