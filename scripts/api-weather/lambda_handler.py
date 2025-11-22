import json
import logging
import urllib.parse
import urllib.request

'''
curl -s "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-weather"
'''

'''
curl -s "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-weather?city=London"
curl -s "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-weather?city=New%20York"
curl -s "https://u4pcumf51e.execute-api.us-east-1.amazonaws.com/api-weather?city=Tokyo"
'''

# --- Logging setup ---
logger = logging.getLogger()
logger.setLevel(logging.INFO)

GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"

COMMON_HEADERS = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
}

# --- Helpers ---
def http_get(url):
    logger.info(f"Fetching URL: {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "t5-api-weather/1.0"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.load(resp)
        return data

def geocode_city(city_name):
    q = urllib.parse.urlencode({"name": city_name, "count": 1})
    url = f"{GEOCODE_URL}?{q}"
    data = http_get(url)
    results = data.get("results")
    if results:
        r = results[0]
        return r["latitude"], r["longitude"], r["name"]
    return None

def get_weather(lat, lon):
    q = urllib.parse.urlencode({"latitude": lat, "longitude": lon, "current_weather": "true"})
    url = f"{FORECAST_URL}?{q}"
    data = http_get(url)
    return data.get("current_weather")

# --- Lambda entrypoint ---
def lambda_handler(event, context):
    logger.info(f"Event received: {json.dumps(event)}")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    # Handle CORS preflight
    if method == "OPTIONS":
        return {"statusCode": 200, "headers": COMMON_HEADERS}

    qs = event.get("queryStringParameters") or {}
    city = qs.get("city") if qs else None

    if not city:
        city = "Buenos Aires"
        logger.info("No city provided, defaulting to Buenos Aires")

    geo = geocode_city(city)
    if not geo:
        return {
            "statusCode": 404,
            "headers": COMMON_HEADERS,
            "body": json.dumps({"error": f"City '{city}' not found"})
        }

    lat, lon, resolved_name = geo
    weather = get_weather(lat, lon)

    if not weather:
        return {
            "statusCode": 502,
            "headers": COMMON_HEADERS,
            "body": json.dumps({"error": "Weather data unavailable"})
        }

    response_body = {
        "city": resolved_name,
        "temperature_C": weather.get("temperature"),
        "windspeed_m_s": weather.get("windspeed"),
        "weather_code": weather.get("weathercode"),
        "time": weather.get("time")
    }

    return {
        "statusCode": 200,
        "headers": COMMON_HEADERS,
        "body": json.dumps(response_body)
    }
