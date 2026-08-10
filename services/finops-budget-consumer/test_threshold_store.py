from datetime import datetime, timedelta, timezone

from google.cloud import firestore
import pytest

from threshold_store import (
    FirestoreThresholdStore,
    ThresholdClaimStatus,
    ThresholdStoreError,
    build_threshold_key,
)


class FakeSnapshot:
    def __init__(self, data=None):
        self._data = data
        self.exists = data is not None

    def to_dict(self):
        return self._data


class FakeDocument:
    def __init__(self, snapshot):
        self.snapshot = snapshot

    def get(self, transaction=None):
        return self.snapshot


class FakeCollection:
    def __init__(self, snapshot):
        self.snapshot = snapshot
        self.document_ids = []

    def document(self, document_id):
        self.document_ids.append(document_id)
        return FakeDocument(self.snapshot)


class FakeTransaction:
    def __init__(self):
        self.set_calls = []
        self.update_calls = []

    def set(self, document, payload):
        self.set_calls.append((document, payload))

    def update(self, document, payload):
        self.update_calls.append((document, payload))


class FakeClient:
    def __init__(self, snapshot):
        self.collection_instance = FakeCollection(snapshot)
        self.transaction_instance = FakeTransaction()
        self.collection_names = []

    def collection(self, collection_name):
        self.collection_names.append(collection_name)
        return self.collection_instance

    def transaction(self):
        return self.transaction_instance


@pytest.fixture(autouse=True)
def fake_transactional(monkeypatch):
    def transactional(function):
        def wrapper(transaction):
            return function(transaction)

        return wrapper

    monkeypatch.setattr(
        "threshold_store.firestore.transactional",
        transactional,
    )


def make_store(data=None):
    client = FakeClient(FakeSnapshot(data))

    store = FirestoreThresholdStore(
        client=client,
        collection_name="test_threshold_notifications",
        lease_duration_seconds=120,
    )

    return store, client


def threshold_identity():
    return {
        "billing_account_id": "01500A-A64D6C-AB73C2",
        "budget_id": "budget-001",
        "cost_interval_start": "2026-08-01T07:00:00Z",
        "threshold": 0.5,
    }


def test_builds_stable_threshold_key():
    first = build_threshold_key(**threshold_identity())
    second = build_threshold_key(**threshold_identity())

    assert first == second
    assert len(first) == 64


def test_different_threshold_has_different_key():
    first = build_threshold_key(**threshold_identity())

    different = {
        **threshold_identity(),
        "threshold": 0.8,
    }
    second = build_threshold_key(**different)

    assert first != second


def test_different_billing_period_has_different_key():
    first = build_threshold_key(**threshold_identity())

    different = {
        **threshold_identity(),
        "cost_interval_start": "2026-09-01T07:00:00Z",
    }
    second = build_threshold_key(**different)

    assert first != second


def test_claims_new_threshold_notification():
    store, client = make_store()

    claim = store.claim(
        threshold_key="threshold-key",
        metadata=threshold_identity(),
        message_id="message-001",
    )

    assert claim.status == ThresholdClaimStatus.CLAIMED
    assert claim.token

    _, payload = client.transaction_instance.set_calls[0]

    assert payload["state"] == "processing"
    assert payload["first_message_id"] == "message-001"
    assert payload["claim_token"] == claim.token
    assert payload["lease_expires_at"] > payload["claimed_at"]


def test_suppresses_delivered_threshold():
    store, client = make_store(
        {
            "state": "delivered",
        }
    )

    claim = store.claim(
        threshold_key="threshold-key",
        metadata=threshold_identity(),
        message_id="message-002",
    )

    assert claim.status == ThresholdClaimStatus.DELIVERED
    assert claim.token is None
    assert client.transaction_instance.set_calls == []


def test_reports_active_threshold_claim():
    store, client = make_store(
        {
            "state": "processing",
            "lease_expires_at": (
                datetime.now(timezone.utc)
                + timedelta(minutes=5)
            ),
        }
    )

    claim = store.claim(
        threshold_key="threshold-key",
        metadata=threshold_identity(),
        message_id="message-002",
    )

    assert claim.status == ThresholdClaimStatus.ACTIVE
    assert claim.token is None
    assert client.transaction_instance.set_calls == []


def test_reclaims_expired_threshold_claim():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "expired-token",
            "lease_expires_at": (
                datetime.now(timezone.utc)
                - timedelta(seconds=1)
            ),
        }
    )

    claim = store.claim(
        threshold_key="threshold-key",
        metadata=threshold_identity(),
        message_id="message-002",
    )

    assert claim.status == ThresholdClaimStatus.CLAIMED
    assert claim.token
    assert claim.token != "expired-token"


def test_marks_owned_threshold_claim_delivered():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "threshold-token",
        }
    )

    result = store.mark_delivered(
        threshold_key="threshold-key",
        claim_token="threshold-token",
        message_id="message-001",
    )

    assert result is True

    _, payload = client.transaction_instance.update_calls[0]

    assert payload["state"] == "delivered"
    assert payload["delivered_message_id"] == "message-001"
    assert "delivered_at" in payload
    assert payload["claim_token"] == firestore.DELETE_FIELD
    assert payload["lease_expires_at"] == firestore.DELETE_FIELD


def test_releases_owned_threshold_claim():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "threshold-token",
        }
    )

    result = store.release(
        threshold_key="threshold-key",
        claim_token="threshold-token",
    )

    assert result is True

    _, payload = client.transaction_instance.update_calls[0]

    assert payload["state"] == "retryable_failure"
    assert payload["claim_token"] == firestore.DELETE_FIELD


def test_wraps_claim_failure():
    store, client = make_store()

    client.transaction_instance.set = (
        lambda document, payload: (
            (_ for _ in ()).throw(
                RuntimeError("Firestore unavailable")
            )
        )
    )

    with pytest.raises(
        ThresholdStoreError,
        match="Failed to claim threshold notification",
    ):
        store.claim(
            threshold_key="threshold-key",
            metadata=threshold_identity(),
            message_id="message-001",
        )