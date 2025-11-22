import json
import logging
import boto3
import time
from datetime import datetime, timedelta

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logs = boto3.client("logs")

LOG_GROUP = "/aws/lambda/t5-api-log"

'''
curl -X GET https://api.aws-serverless.net/api-log \
  -H "Accept: application/json"

curl "https://api.aws-serverless.net/api-log?page=/rds/&hours=12"
'''

'''
curl -X POST https://api.aws-serverless.net/api-log \
  -H "Content-Type: application/json" \
  -H "User-Agent: TestClient/1.0" \
  -H "Referer: https://aws-serverless.net/dash/" \
  -d '{"event": "page_load_rds", "page": "/rds/"}'

You can swap the payload easily, e.g.:
-d '{"event": "page_load_home", "page": "/"}'
'''

def lambda_handler(event, context):
    logger.info("==> Lambda triggered")
    logger.info(f"Incoming event: {json.dumps(event)[:500]}")  # log first 500 chars for context

    logger.info(f"Event raw keys: {list(event.keys())}")
    logger.info(f"RequestContext: {json.dumps(event.get('requestContext', {}))}")

    method = event.get("requestContext", {}).get("http", {}).get("method", "UNKNOWN")
    logger.info(f"HTTP method detected: {method}")

    if method == "POST":
        return handle_post(event)
    elif method == "GET":
        return handle_get(event)
    else:
        logger.warning(f"Unsupported method: {method}")
        return {"statusCode": 405, "body": json.dumps({"error": "Method not allowed"})}


# -------------------------------------------------------
# POST: Write Log Entry
# -------------------------------------------------------
def handle_post(event):
    logger.info("==> handle_post called")

    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        body = {}
        logger.warning("Malformed JSON body; defaulting to empty dict")

    request = event.get("requestContext", {}).get("http", {})
    ip = request.get("sourceIp", "unknown")
    ua = event.get("headers", {}).get("user-agent", "unknown")
    ref = event.get("headers", {}).get("referer", "")
    ev = body.get("event", "unknown_event")
    page = body.get("page", "unknown_page")

    # log_entry = {
    #     "timestamp": datetime.utcnow().isoformat() + "Z",
    #     "ip": ip,
    #     "event": ev,
    #     "page": page,
    #     "user_agent": ua,
    #     "referer": ref
    # }

    log_entry = {
        "timestamp": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
        "ip": ip,
        "event": ev,
        "page": page,
        "user_agent": ua,
        "referer": ref
    }


    logger.info(f"Writing log entry: {json.dumps(log_entry)}")

    # This is what writes to CloudWatch for later query
    logger.info(json.dumps(log_entry))

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"status": "ok"})
    }


# -------------------------------------------------------
# GET: Read Logs
# -------------------------------------------------------
def handle_get(event):
    logger.info("==> handle_get called")

    query = """
    fields @timestamp, @message
    | parse @message '"ip": "*"' as ip
    | parse @message '"event": "*"' as event
    | parse @message '"page": "*"' as page
    | parse @message '"user_agent": "*"' as user_agent
    | parse @message '"referer": "*"' as referer
    | filter ispresent(ip) and ip != "unknown"
    | sort @timestamp desc
    | limit 25
    """

    start = int((time.time() - 86400) * 1000)  # last 24h
    end = int(time.time() * 1000)
    logger.info(f"Running Logs Insights query on {LOG_GROUP} from {start} to {end}")

    try:
        q = logs.start_query(
            logGroupName=LOG_GROUP,
            startTime=start,
            endTime=end,
            queryString=query
        )
        qid = q["queryId"]
        logger.info(f"Started query: {qid}")

        # Poll until complete
        while True:
            res = logs.get_query_results(queryId=qid)
            status = res.get("status")
            logger.info(f"Query status: {status}")
            if status in ["Complete", "Failed", "Cancelled"]:
                break
            time.sleep(1)

        logger.info(f"Query result count: {len(res.get('results', []))}")

        # After res = logs.get_query_results(...)
        # Flatten CloudWatch response
        clean = []
        for row in res.get("results", []):
            entry = {}
            for field in row:
                entry[field["field"]] = field["value"]
            clean.append(entry)

        # Sort by timestamp descending
        clean.sort(key=lambda x: x.get("@timestamp", ""), reverse=True)

        logger.info("NEW CODE WORKING")

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(clean, indent=2)
        }

    except Exception as e:
        logger.exception(f"Error running CloudWatch query: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }