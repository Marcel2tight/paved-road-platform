import base64
import json
import pytest

import app as consumer
from event_store import ClaimStatus, EventClaim
from threshold_store import (
    ThresholdClaim,
    ThresholdClaimStatus,
)


class FakeEventStore:
    def __init__(self):
        self.claim_result = EventClaim(
            status=ClaimStatus.CLAIMED,
            token="test-claim-token",
        )
        self.claim_calls = []
        self.delivered_calls = []
        self.release_calls = []
        self.suppressed_calls = []
        self.mark_delivered_result = True
        self.mark_suppressed_result = True
        self.release_result = True

    def claim(self, message_id, metadata):
        self.claim_calls.append((message_id, metadata))
        return self.claim_result

    def mark_delivered(self, message_id, claim_token):
        self.delivered_calls.append(
            (message_id, claim_token)
        )
        return self.mark_delivered_result

    def mark_suppressed(
        self,
        message_id,
        claim_token,
        threshold_key,
    ):
        self.suppressed_calls.append(
            (message_id, claim_token, threshold_key)
        )
        return self.mark_suppressed_result

    def release(self, message_id, claim_token):
        self.release_calls.append(
            (message_id, claim_token)
        )
        return self.release_result


class FakeThresholdStore:
    def __init__(self):
        self.claim_result = ThresholdClaim(
            status=ThresholdClaimStatus.CLAIMED,
            token="test-threshold-token",
        )
        self.claim_calls = []
        self.delivered_calls = []
        self.release_calls = []
        self.mark_delivered_result = True
        self.release_result = True
        self.mark_delivered_error = None

    def claim(
        self,
        threshold_key,
        metadata,
        message_id,
    ):
        self.claim_calls.append(
            (threshold_key, metadata, message_id)
        )
        return self.claim_result

    def mark_delivered(
        self,
        threshold_key,
        claim_token,
        message_id,
    ):
        if self.mark_delivered_error is not None:
            raise self.mark_delivered_error

        self.delivered_calls.append(
            (threshold_key, claim_token, message_id)
        )
        return self.mark_delivered_result

    def release(
        self,
        threshold_key,
        claim_token,
    ):
        self.release_calls.append(
            (threshold_key, claim_token)
        )
        return self.release_result


@pytest.fixture
def event_store(monkeypatch):
    store = FakeEventStore()

    monkeypatch.setattr(
        consumer,
        "get_event_store",
        lambda: store,
    )

    return store


@pytest.fixture
def threshold_store(monkeypatch):
    store = FakeThresholdStore()

    monkeypatch.setattr(
        consumer,
        "get_threshold_store",
        lambda: store,
        raising=False,
    )

    return store


@pytest.fixture
def client(event_store, threshold_store):
    consumer.app.config.update(TESTING=True)
    return consumer.app.test_client()


def make_envelope(
    threshold=0.8,
    schema_version="1.0",
    budget_id="test-budget-id",
    billing_account_id="000000-000000-000000",
    message_id="test-message-001",
):
    payload = {
        "budgetDisplayName": "Paved Road Platform Budget",
        "costAmount": 42.50,
        "budgetAmount": 50.00,
        "currencyCode": "USD",
        "costIntervalStart": "2026-08-01T00:00:00Z",
    }
    if threshold is not None:
        payload["alertThresholdExceeded"] = threshold

    encoded_data = base64.b64encode(
        json.dumps(payload).encode("utf-8")
    ).decode("utf-8")

    return {
        "subscription": "projects/test-project/subscriptions/test-subscription",
        "message": {
            "data": encoded_data,
            "messageId": message_id,
            "attributes": {
                "billingAccountId": billing_account_id,
                "budgetId": budget_id,
                "schemaVersion": schema_version,
            },
        },
    }


@pytest.mark.parametrize(
    "threshold,expected_severity",
    [
        (0.4, "info"),
        (0.5, "notice"),
        (0.79, "notice"),
        (0.8, "warning"),
        (0.99, "warning"),
        (1.0, "critical"),
        (1.2, "critical"),
    ],
)
def test_classify_severity(threshold, expected_severity):
    assert consumer.classify_severity(threshold) == expected_severity


def test_decode_budget_event():
    envelope = make_envelope(threshold=0.8)
    event = consumer.decode_budget_event(envelope)

    assert event.message_id == "test-message-001"
    assert event.budget_id == "test-budget-id"
    assert event.billing_account_id == "000000-000000-000000"
    assert event.budget_display_name == "Paved Road Platform Budget"
    assert event.cost_amount == 42.50
    assert event.budget_amount == 50.00
    assert event.currency_code == "USD"
    assert event.alert_threshold_exceeded == 0.8
    assert round(event.spend_ratio, 2) == 0.85


def test_rejects_unsupported_schema(client):
    response = client.post(
        "/",
        json=make_envelope(schema_version="2.0"),
    )
    assert response.status_code == 400
    assert "Unsupported Cloud Billing schema version" in response.get_json()["error"]


def test_ignores_event_without_actual_threshold(client):
    response = client.post(
        "/",
        json=make_envelope(threshold=None),
    )
    assert response.status_code == 204


def test_sends_warning_alert(client, event_store, monkeypatch):
    sent_payloads = []

    def fake_send_slack_alert(payload):
        sent_payloads.append(payload)

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        fake_send_slack_alert,
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=0.8),
    )

    assert response.status_code == 204
    assert len(sent_payloads) == 1
    assert "WARNING" in sent_payloads[0]["text"] or "WARNING" in json.dumps(sent_payloads[0])
    assert event_store.claim_calls
    assert event_store.delivered_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert event_store.release_calls == []


def test_returns_retryable_error_when_slack_fails(client, event_store, monkeypatch):
    def fail_delivery(_payload):
        raise consumer.SlackDeliveryError("simulated failure")

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        fail_delivery,
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=1.0),
    )

    assert response.status_code == 503
    assert event_store.release_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert event_store.delivered_calls == []


@pytest.mark.parametrize(
    "claim_status,expected_status_code",
    [
        (ClaimStatus.DELIVERED, 204),
        (ClaimStatus.ACTIVE, 503),
    ],
)
def test_suppresses_duplicate_or_active_claim(
    client,
    event_store,
    monkeypatch,
    claim_status,
    expected_status_code,
):
    event_store.claim_result = EventClaim(
        status=claim_status
    )

    def unexpected_slack_call(_payload):
        raise AssertionError("Slack should not be called.")

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        unexpected_slack_call,
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=0.8),
    )

    assert response.status_code == expected_status_code
    assert event_store.delivered_calls == []
    assert event_store.release_calls == []


def test_returns_retryable_error_when_finalize_fails(
    client,
    event_store,
    monkeypatch,
):
    event_store.mark_delivered_result = False

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        lambda _payload: None,
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=1.0),
    )

    assert response.status_code == 503
    assert event_store.delivered_calls == [
        ("test-message-001", "test-claim-token")
    ]


def test_rejects_missing_message_id(client):
    envelope = make_envelope()
    del envelope["message"]["messageId"]

    response = client.post("/", json=envelope)

    assert response.status_code == 400
    assert "messageId" in response.get_json()["error"]


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "healthy"


def test_metrics_endpoint(client):
    response = client.get("/metrics")
    assert response.status_code == 200


def test_claims_and_finalizes_threshold_notification(
    client,
    event_store,
    threshold_store,
    monkeypatch,
):
    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        lambda _payload: None,
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=0.8),
    )

    assert response.status_code == 204
    assert len(threshold_store.claim_calls) == 1

    threshold_key, metadata, message_id = (
        threshold_store.claim_calls[0]
    )

    assert len(threshold_key) == 64
    assert metadata == {
        "billing_account_id": "000000-000000-000000",
        "budget_id": "test-budget-id",
        "cost_interval_start": "2026-08-01T00:00:00Z",
        "threshold": 0.8,
    }
    assert message_id == "test-message-001"

    assert threshold_store.delivered_calls == [
        (
            threshold_key,
            "test-threshold-token",
            "test-message-001",
        )
    ]
    assert threshold_store.release_calls == []

    assert event_store.delivered_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert event_store.suppressed_calls == []


def test_suppresses_already_delivered_threshold(
    client,
    event_store,
    threshold_store,
    monkeypatch,
):
    threshold_store.claim_result = ThresholdClaim(
        status=ThresholdClaimStatus.DELIVERED
    )

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        lambda _payload: pytest.fail(
            "Slack should not be called."
        ),
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=0.8),
    )

    assert response.status_code == 204
    assert len(threshold_store.claim_calls) == 1

    threshold_key = threshold_store.claim_calls[0][0]

    assert event_store.suppressed_calls == [
        (
            "test-message-001",
            "test-claim-token",
            threshold_key,
        )
    ]
    assert event_store.delivered_calls == []
    assert event_store.release_calls == []


def test_retries_when_threshold_claim_is_active(
    client,
    event_store,
    threshold_store,
    monkeypatch,
):
    threshold_store.claim_result = ThresholdClaim(
        status=ThresholdClaimStatus.ACTIVE
    )

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        lambda _payload: pytest.fail(
            "Slack should not be called."
        ),
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=0.8),
    )

    assert response.status_code == 503
    assert event_store.release_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert event_store.delivered_calls == []
    assert event_store.suppressed_calls == []


def test_releases_both_claims_when_slack_fails(
    client,
    event_store,
    threshold_store,
    monkeypatch,
):
    def fail_delivery(_payload):
        raise consumer.SlackDeliveryError(
            "simulated failure"
        )

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        fail_delivery,
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=1.0),
    )

    assert response.status_code == 503

    threshold_key = threshold_store.claim_calls[0][0]

    assert threshold_store.release_calls == [
        (threshold_key, "test-threshold-token")
    ]
    assert event_store.release_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert threshold_store.delivered_calls == []
    assert event_store.delivered_calls == []


def test_releases_event_claim_when_threshold_finalization_is_rejected(
    client,
    event_store,
    threshold_store,
    monkeypatch,
):
    slack_calls = []

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        lambda payload: slack_calls.append(payload),
    )

    threshold_store.mark_delivered_result = False

    response = client.post(
        "/",
        json=make_envelope(threshold=1.0),
    )

    assert response.status_code == 503
    assert len(slack_calls) == 1

    assert event_store.release_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert event_store.delivered_calls == []

    # The threshold claim must not be released after Slack accepted
    # the notification because the finalization outcome is uncertain.
    assert threshold_store.release_calls == []


def test_releases_event_claim_when_threshold_finalization_raises(
    client,
    event_store,
    threshold_store,
    monkeypatch,
):
    slack_calls = []

    monkeypatch.setattr(
        consumer,
        "send_slack_alert",
        lambda payload: slack_calls.append(payload),
    )

    threshold_store.mark_delivered_error = (
        consumer.ThresholdStoreError(
            "simulated finalization failure"
        )
    )

    response = client.post(
        "/",
        json=make_envelope(threshold=0.8),
    )

    assert response.status_code == 503
    assert len(slack_calls) == 1

    assert event_store.release_calls == [
        ("test-message-001", "test-claim-token")
    ]
    assert event_store.delivered_calls == []
    assert threshold_store.release_calls == []