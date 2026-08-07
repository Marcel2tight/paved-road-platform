import base64
import binascii
import json
import logging
import os
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from functools import lru_cache
from typing import Any

from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

from event_store import (
    ClaimStatus,
    EventStoreError,
    FirestoreEventStore,
)


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": self.formatTime(record, self.datefmt),
            "severity": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }

        for field in (
            "message_id",
            "budget_id",
            "budget_name",
            "billing_account_id",
            "threshold",
            "status_code",
            "duration_ms",
        ):
            if hasattr(record, field):
                payload[field] = getattr(record, field)

        return json.dumps(payload)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())

logger = logging.getLogger("finops-budget-consumer")
logger.setLevel(logging.INFO)
logger.handlers.clear()
logger.addHandler(handler)
logger.propagate = False

app = Flask(__name__)

SERVICE_NAME = os.getenv("SERVICE_NAME", "finops-budget-consumer")
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")
START_TIME = time.time()

EVENTS_RECEIVED = Counter(
    "paved_road_finops_budget_events_received_total",
    "Total Cloud Billing budget events received.",
)

EVENTS_PROCESSED = Counter(
    "paved_road_finops_budget_events_processed_total",
    "Budget events successfully processed.",
    ["result", "severity"],
)

EVENTS_FAILURES = Counter(
    "paved_road_finops_budget_event_failures_total",
    "Budget-event processing failures.",
    ["failure_type"],
)

EVENTS_DUPLICATES = Counter(
    "paved_road_finops_budget_event_duplicates_total",
    "Budget events suppressed by persistent deduplication.",
    ["claim_status"],
)

PROCESSING_DURATION = Histogram(
    "paved_road_finops_budget_event_duration_seconds",
    "Budget-event processing duration in seconds.",
)


@lru_cache(maxsize=1)
def get_event_store() -> FirestoreEventStore:
    return FirestoreEventStore()


@dataclass(frozen=True)
class BudgetEvent:
    message_id: str
    budget_id: str
    billing_account_id: str
    schema_version: str
    budget_display_name: str
    cost_amount: float
    budget_amount: float
    currency_code: str
    cost_interval_start: str
    alert_threshold_exceeded: float | None

    @property
    def spend_ratio(self) -> float:
        if self.budget_amount <= 0:
            return 0
        return self.cost_amount / self.budget_amount


class InvalidEvent(ValueError):
    pass


class SlackDeliveryError(RuntimeError):
    pass


def decode_budget_event(envelope: Any) -> BudgetEvent:
    if not isinstance(envelope, dict):
        raise InvalidEvent("Request body must be a JSON object.")

    message = envelope.get("message")
    if not isinstance(message, dict):
        raise InvalidEvent("Pub/Sub envelope is missing message.")

    message_id = message.get("messageId") or message.get("message_id")
    if not isinstance(message_id, str) or not message_id.strip():
        raise InvalidEvent("Pub/Sub message is missing messageId.")

    encoded_data = message.get("data")
    if not isinstance(encoded_data, str) or not encoded_data:
        raise InvalidEvent("Pub/Sub message is missing base64 data.")

    attributes = message.get("attributes") or {}
    if not isinstance(attributes, dict):
        raise InvalidEvent("Pub/Sub message attributes must be an object.")

    schema_version = attributes.get("schemaVersion")
    if schema_version != "1.0":
        raise InvalidEvent(
            f"Unsupported Cloud Billing schema version: {schema_version!r}."
        )

    try:
        decoded = base64.b64decode(encoded_data, validate=True)
        payload = json.loads(decoded.decode("utf-8"))
    except (binascii.Error, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise InvalidEvent("Pub/Sub message contains invalid encoded JSON.") from error

    if not isinstance(payload, dict):
        raise InvalidEvent("Decoded budget event must be a JSON object.")

    required_fields = (
        "budgetDisplayName",
        "costAmount",
        "budgetAmount",
        "currencyCode",
        "costIntervalStart",
    )

    missing_fields = [
        field for field in required_fields
        if field not in payload
    ]

    if missing_fields:
        raise InvalidEvent(
            f"Budget event is missing required fields: {', '.join(missing_fields)}."
        )

    try:
        cost_amount = float(payload["costAmount"])
        budget_amount = float(payload["budgetAmount"])
        threshold = payload.get("alertThresholdExceeded")
        alert_threshold = float(threshold) if threshold is not None else None
    except (TypeError, ValueError) as error:
        raise InvalidEvent("Budget amounts and thresholds must be numeric.") from error

    if budget_amount <= 0:
        raise InvalidEvent("budgetAmount must be greater than zero.")

    return BudgetEvent(
        message_id=message_id,
        budget_id=str(attributes.get("budgetId") or "unknown"),
        billing_account_id=str(attributes.get("billingAccountId") or "unknown"),
        schema_version=schema_version,
        budget_display_name=str(payload["budgetDisplayName"]),
        cost_amount=cost_amount,
        budget_amount=budget_amount,
        currency_code=str(payload["currencyCode"]),
        cost_interval_start=str(payload["costIntervalStart"]),
        alert_threshold_exceeded=alert_threshold,
    )


def classify_severity(threshold: float) -> str:
    if threshold >= 1.0:
        return "critical"
    if threshold >= 0.8:
        return "warning"
    if threshold >= 0.5:
        return "notice"
    return "info"


def build_slack_message(event: BudgetEvent, severity: str) -> dict[str, Any]:
    severity_icons = {
        "critical": ":rotating_light:",
        "warning": ":warning:",
        "notice": ":large_yellow_circle:",
        "info": ":information_source:",
    }

    threshold_percent = (
        event.alert_threshold_exceeded * 100
        if event.alert_threshold_exceeded is not None
        else 0
    )

    spend_percent = event.spend_ratio * 100

    return {
        "text": (
            f"{severity_icons[severity]} Paved Road budget alert: "
            f"{event.budget_display_name}"
        ),
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"Paved Road FinOps — {severity.upper()}",
                },
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Budget:*\n{event.budget_display_name}",
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Billing account:*\n{event.billing_account_id}",
                    },
                    {
                        "type": "mrkdwn",
                        "text": (
                            f"*Current spend:*\n"
                            f"{event.currency_code} {event.cost_amount:,.2f}"
                        ),
                    },
                    {
                        "type": "mrkdwn",
                        "text": (
                            f"*Budget amount:*\n"
                            f"{event.currency_code} {event.budget_amount:,.2f}"
                        ),
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Spend percentage:*\n{spend_percent:.1f}%",
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Threshold exceeded:*\n{threshold_percent:.0f}%",
                    },
                ],
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": (
                            f"Budget period started {event.cost_interval_start} "
                            f"| Message ID: {event.message_id}"
                        ),
                    }
                ],
            },
        ],
    }


def send_slack_alert(payload: dict[str, Any]) -> None:
    if not SLACK_WEBHOOK_URL:
        raise SlackDeliveryError("SLACK_WEBHOOK_URL is not configured.")

    body = json.dumps(payload).encode("utf-8")
    slack_request = urllib.request.Request(
        SLACK_WEBHOOK_URL,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(slack_request, timeout=10) as response:
            if response.status < 200 or response.status >= 300:
                raise SlackDeliveryError(
                    f"Slack returned HTTP {response.status}."
                )
    except (urllib.error.URLError, TimeoutError) as error:
        raise SlackDeliveryError("Slack webhook delivery failed.") from error


@app.get("/health")
def health():
    return jsonify(
        {
            "status": "healthy",
            "service": SERVICE_NAME,
            "uptime_seconds": round(time.time() - START_TIME, 2),
        }
    )


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.post("/")
def consume_budget_event():
    started_at = time.perf_counter()
    EVENTS_RECEIVED.inc()

    try:
        event = decode_budget_event(request.get_json(silent=True))

        if event.alert_threshold_exceeded is None:
            EVENTS_PROCESSED.labels(
                result="ignored",
                severity="none",
            ).inc()

            logger.info(
                "Budget event did not exceed an actual-cost threshold",
                extra={
                    "message_id": event.message_id,
                    "budget_id": event.budget_id,
                    "budget_name": event.budget_display_name,
                    "billing_account_id": event.billing_account_id,
                },
            )

            return "", 204

        severity = classify_severity(
            event.alert_threshold_exceeded
        )

        event_store = get_event_store()
        claim = event_store.claim(
            event.message_id,
            {
                "budget_id": event.budget_id,
                "budget_name": event.budget_display_name,
                "billing_account_id": event.billing_account_id,
                "threshold": event.alert_threshold_exceeded,
                "severity": severity,
            },
        )

        if claim.status in (
            ClaimStatus.DELIVERED,
            ClaimStatus.ACTIVE,
        ):
            EVENTS_DUPLICATES.labels(
                claim_status=claim.status.value,
            ).inc()

            EVENTS_PROCESSED.labels(
                result="duplicate_suppressed",
                severity=severity,
            ).inc()

            logger.info(
                "Duplicate budget event suppressed",
                extra={
                    "message_id": event.message_id,
                    "budget_id": event.budget_id,
                    "budget_name": event.budget_display_name,
                    "billing_account_id": event.billing_account_id,
                    "threshold": event.alert_threshold_exceeded,
                    "claim_status": claim.status.value,
                },
            )

            return "", 204

        if not claim.token:
            raise EventStoreError(
                "Claimed budget event has no claim token."
            )

        slack_payload = build_slack_message(event, severity)

        try:
            send_slack_alert(slack_payload)
        except SlackDeliveryError:
            try:
                released = event_store.release(
                    event.message_id,
                    claim.token,
                )

                if not released:
                    logger.warning(
                        "Budget-event claim was not released",
                        extra={
                            "message_id": event.message_id,
                            "budget_id": event.budget_id,
                        },
                    )
            except EventStoreError:
                logger.exception(
                    "Failed to release budget-event claim",
                    extra={
                        "message_id": event.message_id,
                        "budget_id": event.budget_id,
                    },
                )

            raise

        delivered = event_store.mark_delivered(
            event.message_id,
            claim.token,
        )

        if not delivered:
            raise EventStoreError(
                "Budget event was delivered to Slack, but its "
                "persistent state could not be finalized."
            )

        EVENTS_PROCESSED.labels(
            result="alert_sent",
            severity=severity,
        ).inc()

        logger.info(
            "Budget alert delivered",
            extra={
                "message_id": event.message_id,
                "budget_id": event.budget_id,
                "budget_name": event.budget_display_name,
                "billing_account_id": event.billing_account_id,
                "threshold": event.alert_threshold_exceeded,
            },
        )

        return "", 204

    except InvalidEvent as error:
        EVENTS_FAILURES.labels(failure_type="invalid_event").inc()
        logger.warning("Invalid budget event: %s", error)
        return jsonify({"error": str(error)}), 400

    except SlackDeliveryError as error:
        EVENTS_FAILURES.labels(failure_type="slack_delivery").inc()
        logger.exception("Retryable Slack delivery failure: %s", error)
        return jsonify({"error": "Alert delivery failed."}), 503

    except EventStoreError as error:
        EVENTS_FAILURES.labels(
            failure_type="event_store"
        ).inc()
        logger.exception(
            "Retryable persistent event-state failure: %s",
            error,
        )
        return jsonify(
            {"error": "Persistent event-state operation failed."}
        ), 503

    except Exception:
        EVENTS_FAILURES.labels(failure_type="unexpected").inc()
        logger.exception("Unexpected budget-event processing failure")
        return jsonify({"error": "Unexpected processing failure."}), 500

    finally:
        PROCESSING_DURATION.observe(time.perf_counter() - started_at)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    app.run(host="0.0.0.0", port=port)