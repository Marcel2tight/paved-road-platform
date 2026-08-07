from datetime import datetime, timedelta, timezone
from google.cloud import firestore
import pytest

from event_store import (
    ClaimStatus,
    EventStoreError,
    FirestoreEventStore,
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
        self.get_calls = []

    def get(self, transaction=None):
        self.get_calls.append(transaction)
        return self.snapshot


class FakeCollection:
    def __init__(self, document):
        self.document_instance = document
        self.document_ids = []

    def document(self, document_id):
        self.document_ids.append(document_id)
        return self.document_instance


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
        self.document_instance = FakeDocument(snapshot)
        self.collection_instance = FakeCollection(
            self.document_instance
        )
        self.transaction_instance = FakeTransaction()
        self.collection_names = []

    def collection(self, collection_name):
        self.collection_names.append(collection_name)
        return self.collection_instance

    def transaction(self):
        return self.transaction_instance


@pytest.fixture(autouse=True)
def execute_transaction_directly(monkeypatch):
    def transactional(function):
        def wrapper(transaction):
            return function(transaction)

        return wrapper

    monkeypatch.setattr(
        "event_store.firestore.transactional",
        transactional,
    )


def make_store(data=None):
    client = FakeClient(FakeSnapshot(data))

    store = FirestoreEventStore(
        client=client,
        collection_name="test_events",
        lease_duration_seconds=120,
    )

    return store, client


def test_claims_new_event():
    store, client = make_store()

    claim = store.claim(
        "message-001",
        {
            "budget_id": "budget-001",
            "state": "malicious-metadata-state",
        },
    )

    assert claim.status == ClaimStatus.CLAIMED
    assert claim.token

    assert client.collection_names == ["test_events"]
    assert client.collection_instance.document_ids == [
        "message-001"
    ]

    assert len(client.transaction_instance.set_calls) == 1

    _, payload = client.transaction_instance.set_calls[0]

    assert payload["message_id"] == "message-001"
    assert payload["budget_id"] == "budget-001"
    assert payload["state"] == "processing"
    assert payload["claim_token"] == claim.token
    assert payload["lease_expires_at"] > payload["claimed_at"]
    assert payload["updated_at"] == payload["claimed_at"]


def test_suppresses_delivered_event():
    store, client = make_store(
        {
            "state": "delivered",
        }
    )

    claim = store.claim("message-001", {})

    assert claim.status == ClaimStatus.DELIVERED
    assert claim.token is None
    assert client.transaction_instance.set_calls == []


def test_suppresses_active_processing_lease():
    store, client = make_store(
        {
            "state": "processing",
            "lease_expires_at": (
                datetime.now(timezone.utc)
                + timedelta(minutes=5)
            ),
        }
    )

    claim = store.claim("message-001", {})

    assert claim.status == ClaimStatus.ACTIVE
    assert claim.token is None
    assert client.transaction_instance.set_calls == []


def test_reclaims_expired_processing_lease():
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

    claim = store.claim("message-001", {})

    assert claim.status == ClaimStatus.CLAIMED
    assert claim.token
    assert claim.token != "expired-token"
    assert len(client.transaction_instance.set_calls) == 1

    _, payload = client.transaction_instance.set_calls[0]

    assert payload["state"] == "processing"
    assert payload["claim_token"] == claim.token


def test_reclaims_retryable_failure():
    store, client = make_store(
        {
            "state": "retryable_failure",
        }
    )

    claim = store.claim("message-001", {})

    assert claim.status == ClaimStatus.CLAIMED
    assert claim.token
    assert len(client.transaction_instance.set_calls) == 1


def test_marks_matching_claim_delivered():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "claim-token",
        }
    )

    result = store.mark_delivered(
        "message-001",
        "claim-token",
    )

    assert result is True
    assert len(client.transaction_instance.update_calls) == 1

    _, payload = client.transaction_instance.update_calls[0]

    assert payload["state"] == "delivered"
    assert "delivered_at" in payload
    assert "updated_at" in payload
    assert payload["claim_token"] == firestore.DELETE_FIELD
    assert payload["lease_expires_at"] == firestore.DELETE_FIELD


@pytest.mark.parametrize(
    "document_data",
    [
        None,
        {
            "state": "delivered",
            "claim_token": "claim-token",
        },
        {
            "state": "processing",
            "claim_token": "different-token",
        },
    ],
)
def test_does_not_finalize_unowned_claim(document_data):
    store, client = make_store(document_data)

    result = store.mark_delivered(
        "message-001",
        "claim-token",
    )

    assert result is False
    assert client.transaction_instance.update_calls == []


def test_releases_matching_claim():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "claim-token",
        }
    )

    result = store.release(
        "message-001",
        "claim-token",
    )

    assert result is True
    assert len(client.transaction_instance.update_calls) == 1

    _, payload = client.transaction_instance.update_calls[0]

    assert payload["state"] == "retryable_failure"
    assert payload["lease_expires_at"] == payload["updated_at"]
    assert payload["claim_token"] == firestore.DELETE_FIELD


@pytest.mark.parametrize(
    "document_data",
    [
        None,
        {
            "state": "delivered",
            "claim_token": "claim-token",
        },
        {
            "state": "processing",
            "claim_token": "different-token",
        },
    ],
)
def test_does_not_release_unowned_claim(document_data):
    store, client = make_store(document_data)

    result = store.release(
        "message-001",
        "claim-token",
    )

    assert result is False
    assert client.transaction_instance.update_calls == []


def test_wraps_claim_failure():
    store, client = make_store()

    client.document_instance.get = lambda transaction=None: (
        (_ for _ in ()).throw(RuntimeError("Firestore unavailable"))
    )

    with pytest.raises(
        EventStoreError,
        match="Failed to claim budget event",
    ):
        store.claim("message-001", {})


def test_wraps_finalize_failure():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "claim-token",
        }
    )

    client.transaction_instance.update = (
        lambda document, payload: (
            (_ for _ in ()).throw(
                RuntimeError("Firestore unavailable")
            )
        )
    )

    with pytest.raises(
        EventStoreError,
        match="Failed to mark budget event as delivered",
    ):
        store.mark_delivered(
            "message-001",
            "claim-token",
        )


def test_wraps_release_failure():
    store, client = make_store(
        {
            "state": "processing",
            "claim_token": "claim-token",
        }
    )

    client.transaction_instance.update = (
        lambda document, payload: (
            (_ for _ in ()).throw(
                RuntimeError("Firestore unavailable")
            )
        )
    )

    with pytest.raises(
        EventStoreError,
        match="Failed to release budget-event claim",
    ):
        store.release(
            "message-001",
            "claim-token",
        )