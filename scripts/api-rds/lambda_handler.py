import json
import os
import boto3
import pg8000
import logging

'''

# CREATE
curl -X POST "https://api.aws-serverless.net/api-rds" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe", "email": "jane@example.com", "phone": "555-1111"}'

# {"id": 55}  

# LIST ALL
curl -X GET "https://api.aws-serverless.net/api-rds"

# GET ONE
curl -X GET "https://api.aws-serverless.net/api-rds/56"

# UPDATE
curl -X PUT "https://api.aws-serverless.net/api-rds/56" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Updated", "email": "jane@example.com", "phone": "555-2222"}'

# DELETE
curl -X DELETE "https://api.aws-serverless.net/api-rds/47"

# CORS preflight (root)
curl -X OPTIONS "https://api.aws-serverless.net/api-rds" \
  -H "Access-Control-Request-Method: POST" \
  -H "Origin: https://aws-serverless.net"

# CORS preflight (by ID)
curl -X OPTIONS "https://api.aws-serverless.net/api-rds/47" \
  -H "Access-Control-Request-Method: GET" \
  -H "Origin: https://aws-serverless.net"


'''




# ---------- Logging setup ----------
logger = logging.getLogger()
logger.setLevel(logging.INFO)


# ---------- Database helpers ----------
def get_db_connection():
    logger.info("Opening DB connection")
    secret_arn = os.environ['SECRET_ARN']
    db_host = os.environ['DB_HOST']
    secret_client = boto3.client('secretsmanager')

    secret = secret_client.get_secret_value(SecretId=secret_arn)
    creds = json.loads(secret['SecretString'])

    conn = pg8000.connect(
        user=creds['username'],
        password=creds['password'],
        host=db_host,
        database="maindb",
        port=5432
    )
    return conn

def create_table(conn):
    logger.info("Ensuring demo_contacts table exists")
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS demo_contacts (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT,
            created_at TIMESTAMP DEFAULT now()
        );
    """)
    conn.commit()
    cursor.close()

# ---------- CRUD operations ----------
def get_all_contacts(conn):
    logger.info("Fetching all contacts")
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, email, phone, created_at FROM demo_contacts")
    rows = cursor.fetchall()
    cursor.close()
    return [
        {"id": r[0], "name": r[1], "email": r[2], "phone": r[3], "created_at": str(r[4])}
        for r in rows
    ]

def get_contact_by_id(conn, id_value):
    cur = conn.cursor()
    cur.execute("SELECT id, name, email, phone, created_at FROM demo_contacts WHERE id = %s", (id_value,))
    row = cur.fetchone()
    cur.close()
    if not row:
        return None
    return {
        "id": row[0],
        "name": row[1],
        "email": row[2],
        "phone": row[3],
        "created_at": str(row[4]),
    }

def create_contact(conn, body):
    logger.info("Inserting new contact: %s", body)
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO demo_contacts (name, email, phone) VALUES (%s, %s, %s) RETURNING id",
        (body.get("name"), body.get("email"), body.get("phone"))
    )
    new_id = cursor.fetchone()[0]
    conn.commit()
    cursor.close()
    logger.info("Contact created with id=%s", new_id)
    return {"id": new_id}

def update_contact(conn, contact_id, body):
    contact_id = int(contact_id)
    logger.info("Updating contact id=%s with %s", contact_id, body)
    cur = conn.cursor()
    cur.execute("""
        UPDATE demo_contacts
        SET name=%s, email=%s, phone=%s
        WHERE id=%s
    """, (body.get("name"), body.get("email"), body.get("phone"), contact_id))
    conn.commit()
    cur.close()
    return {"updated": True}

def delete_contact(conn, contact_id):
    contact_id = int(contact_id)
    logger.info("Deleting contact id=%s", contact_id)
    cur = conn.cursor()
    cur.execute("DELETE FROM demo_contacts WHERE id=%s", (contact_id,))
    conn.commit()
    cur.close()
    logger.info("Contact id=%s deleted", contact_id)
    return {"deleted": True}

def lambda_handler(event, context):
    logger.info("Event received: %s", json.dumps(event))
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path_params = event.get("pathParameters") or {}
    id_value = path_params.get("id")
    body = json.loads(event.get("body", "{}") or "{}")

    conn = None
    try:
        conn = get_db_connection()
        create_table(conn)

        if method == "GET":
            if id_value:
                result = get_contact_by_id(conn, int(id_value))
                return response(200, result or {"error": "Not found"})
            else:
                return response(200, get_all_contacts(conn))

        elif method == "POST":
            return response(200, create_contact(conn, body))

        elif method == "PUT":
            if not id_value:
                return response(400, {"error": "Missing ID"})
            return response(200, update_contact(conn, int(id_value), body))

        elif method == "DELETE":
            if not id_value:
                return response(400, {"error": "Missing ID"})
            return response(200, delete_contact(conn, int(id_value)))

        else:
            return response(400, {"error": f"Unsupported method: {method}"})

    except Exception as e:
        logger.exception("Error during request processing: %s", str(e))
        return response(500, {"error": str(e)})

    finally:
        if conn:
            conn.close()
            logger.info("DB connection closed")


def response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }
