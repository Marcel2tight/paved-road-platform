import os
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Any

from google.cloud import firestore


FIRESTORE_COLLECTION = os.getenv(
    "FIRESTORE_COLLECTION",
    "finops_budget_events",
)

LEASE_DURATION_SECONDS = int(
    os.getenv("EVENT_LEASE_DURATION_SECONDS", "120")
)


class ClaimStatus(str, Enum):
    CLAIMED = "claimed"
    DELIVERED = "delivered"
    ACTIVE = "active"


@dataclass(frozen=True)
class EventClaim:
    status: ClaimStatus
    token: str | None = None


class EventStoreError(Exception):
    """Raised when persistent event-state operations fail."""


class FirestoreEventStore:
    def __init__(
        self,
        client: firestore.Client | None = None,
        collection_name: str = FIRESTORE_COLLECTION,
        lease_duration_seconds: int = LEASE_DURATION_SECONDS,
    ) -> None:
        self.client = client or firestore.Client()
        self.collection = self.client.collection(collection_name)
        self.lease_duration = timedelta(
            seconds=lease_duration_seconds
        )

    def claim(
        self,
        message_id: str,
        metadata: dict[str, Any],
    ) -> EventClaim:
        document = self.collection.document(message_id)
        transaction = self.client.transaction()
        now = datetime.now(timezone.utc)
        claim_token = str(uuid.uuid4())

        @firestore.transactional
        def claim_in_transaction(current_transaction):
            snapshot = document.get(
                transaction=current_transaction
            )

            if snapshot.exists:
                current_state = snapshot.to_dict() or {}
                state = current_state.get("state")

                if state == "delivered":
                    return EventClaim(
                        status=ClaimStatus.DELIVERED
                    )

                lease_expires_at = current_state.get(
                    "lease_expires_at"
                )

                if (
                    state == "processing"
                    and lease_expires_at is not None
                    and lease_expires_at > now
                ):
                    return EventClaim(
                        status=ClaimStatus.ACTIVE
                    )

            current_transaction.set(
                document,
                {
                    **metadata,
                    "message_id": message_id,
                    "state": "processing",
                    "claim_token": claim_token,
                    "lease_expires_at": now + self.lease_duration,
                    "claimed_at": now,
                    "updated_at": now,
                },
            )

            return EventClaim(
                status=ClaimStatus.CLAIMED,
                token=claim_token,
            )

        try:
            return claim_in_transaction(transaction)
        except Exception as error:
            raise EventStoreError(
                "Failed to claim budget event."
            ) from error

    def mark_delivered(
        self,
        message_id: str,
        claim_token: str,
    ) -> bool:
        document = self.collection.document(message_id)
        transaction = self.client.transaction()
        now = datetime.now(timezone.utc)

        @firestore.transactional
        def deliver_in_transaction(current_transaction):
            snapshot = document.get(
                transaction=current_transaction
            )

            if not snapshot.exists:
                return False

            current_state = snapshot.to_dict() or {}

            if (
                current_state.get("state") != "processing"
                or current_state.get("claim_token") != claim_token
            ):
                return False

            current_transaction.update(
                document,
                {
                    "state": "delivered",
                    "delivered_at": now,
                    "updated_at": now,
                    "claim_token": firestore.DELETE_FIELD,
                    "lease_expires_at": firestore.DELETE_FIELD,
                },
            )

            return True

        try:
            return deliver_in_transaction(transaction)
        except Exception as error:
            raise EventStoreError(
                "Failed to mark budget event as delivered."
            ) from error

    def release(
        self,
        message_id: str,
        claim_token: str,
    ) -> bool:
        document = self.collection.document(message_id)
        transaction = self.client.transaction()
        now = datetime.now(timezone.utc)

        @firestore.transactional
        def release_in_transaction(current_transaction):
            snapshot = document.get(
                transaction=current_transaction
            )

            if not snapshot.exists:
                return False

            current_state = snapshot.to_dict() or {}

            if (
                current_state.get("state") != "processing"
                or current_state.get("claim_token") != claim_token
            ):
                return False

            current_transaction.update(
                document,
                {
                    "state": "retryable_failure",
                    "updated_at": now,
                    "lease_expires_at": now,
                    "claim_token": firestore.DELETE_FIELD,
                },
            )

            return True

        try:
            return release_in_transaction(transaction)
        except Exception as error:
            raise EventStoreError(
                "Failed to release budget-event claim."
            ) from error