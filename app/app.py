import json
import logging
import os
import time
from flask import Flask, Response, jsonify, request
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    Info,
    generate_latest,
)

class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, self.datefmt),
            "severity": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }
        if hasattr(record, "http_method"):
            payload["http_method"] = record.http_method
        if hasattr(record, "http_path"):
            payload["http_path"] = record.http_path
        if hasattr(record, "status_code"):
            payload["status_code"] = record.status_code
        if hasattr(record, "duration_ms"):
            payload["duration_ms"] = record.duration_ms
        return json.dumps(payload)

handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger = logging.getLogger("paved-road-platform")
logger.setLevel(logging.INFO)
logger.handlers.clear()
logger.addHandler(handler)
logger.propagate = False

app = Flask(__name__)

SERVICE_NAME = os.getenv("SERVICE_NAME", "paved-road-reference-app")
PLATFORM = os.getenv("PLATFORM", "paved-road-platform")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
VERSION = os.getenv("APP_VERSION", "v1.0.0")
COMMIT_SHA = os.getenv("COMMIT_SHA", "unknown")
START_TIME = time.time()

HTTP_REQUESTS = Counter(
    "paved_road_http_requests_total",
    "Total HTTP requests handled by the reference application.",
    ["method", "endpoint", "status_code"],
)
HTTP_LATENCY = Histogram(
    "paved_road_http_request_duration_seconds",
    "HTTP request latency in seconds.",
    ["method", "endpoint"],
)
BUILD_INFO = Info(
    "paved_road_build",
    "Build and deployment information for the reference application.",
)
BUILD_INFO.info({
    "service": SERVICE_NAME,
    "platform": PLATFORM,
    "environment": ENVIRONMENT,
    "version": VERSION,
    "commit_sha": COMMIT_SHA,
})

@app.before_request
def start_request_timer() -> None:
    request.request_start_time = time.perf_counter()

@app.after_request
def record_request(response):
    duration_seconds = time.perf_counter() - request.request_start_time
    endpoint = request.path
    HTTP_REQUESTS.labels(
        method=request.method,
        endpoint=endpoint,
        status_code=str(response.status_code),
    ).inc()
    HTTP_LATENCY.labels(
        method=request.method,
        endpoint=endpoint,
    ).observe(duration_seconds)
    logger.info(
        "HTTP request completed",
        extra={
            "http_method": request.method,
            "http_path": endpoint,
            "status_code": response.status_code,
            "duration_ms": round(duration_seconds * 1000, 2),
        },
    )
    return response

@app.get("/")
def index():
    return jsonify({
        "status": "active",
        "service": SERVICE_NAME,
        "platform": PLATFORM,
        "environment": ENVIRONMENT,
        "version": VERSION,
        "commit_sha": COMMIT_SHA,
    })

@app.get("/health")
def health():
    return jsonify({
        "status": "healthy",
        "service": SERVICE_NAME,
        "uptime_seconds": round(time.time() - START_TIME, 2),
    })

@app.get("/ready")
def ready():
    return jsonify({
        "status": "ready",
        "service": SERVICE_NAME,
    })

@app.get("/version")
def version():
    return jsonify({
        "service": SERVICE_NAME,
        "version": VERSION,
        "commit_sha": COMMIT_SHA,
    })

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)
