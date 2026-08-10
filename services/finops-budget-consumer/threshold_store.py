import hashlib
import json
import os
import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from enum import Enum
from typing import Any

from google.cloud import firestore


THRESHOLD_NOTIFICATIONS_COLLECTION = os.getenv(
    "THRESHOLD_NOTIFICATIONS_COLLECTION",
    "budget-threshold-notifications",
)

LEASE_DURATION_SECONDS = int(
    os.getenv("EVENT_LEASE_DURATION_SECONDS", "120")
)


class ThresholdClaimStatus(str, Enum):
    CLAIMED = "claimed"
    DELIVERED = "delivered"
    ACTIVE = "active"


@dataclass(frozen=True)
class ThresholdClaim:
    status: ThresholdClaimStatus
    token: str | None = None


class ThresholdStoreError(Exception):
    """Raised when persistent threshold-state operations fail."""


def build_threshold_key(
    billing_account_id: str,
    budget_id: str,
    cost_interval_start: str,
    threshold: float,
) -> str:
    identity = {
        "billing_account_id": billing_account_id,
        "budget_id": budget_id,
        "cost_interval_start": cost_interval_start,
        "threshold": threshold,
    }

    canonical_identity = json.dumps(
        identity,
        sort_keys=True,
        separators=(",", ":"),
    )

    return hashlib.sha256(
        canonical_identity.encode("utf-8")
    ).hexdigest()


class FirestoreThresholdStore:
    def __init__(
        self,
        client: firestore.Client | None = None,
        collection_name: str = THRESHOLD_NOTIFICATIONS_COLLECTION,
        lease_duration_seconds: int = LEASE_DURATION_SECONDS,
    ) -> None:
        self.client = client or firestore.Client()
        self.collection = self.client.collection(collection_name)
        self.lease_duration = timedelta(
            seconds=lease_duration_seconds
        )

    def claim(
        self,
        threshold_key: str,
        metadata: dict[str, Any],
        message_id: str,
    ) -> ThresholdClaim:
        document = self.collection.document(threshold_key)
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
                    return ThresholdClaim(
                        status=ThresholdClaimStatus.DELIVERED
                    )

                lease_expires_at = current_state.get(
                    "lease_expires_at"
                )

                if (
                    state == "processing"
                    and lease_expires_at is not None
                    and lease_expires_at > now
                ):
                    return ThresholdClaim(
                        status=ThresholdClaimStatus.ACTIVE
                    )

            current_transaction.set(
                document,
                {
                    **metadata,
                    "threshold_key": threshold_key,
                    "state": "processing",
                    "first_message_id": message_id,
                    "claim_token": claim_token,
                    "lease_expires_at": now + self.lease_duration,
                    "claimed_at": now,
                    "updated_at": now,
                },
            )

            return ThresholdClaim(
                status=ThresholdClaimStatus.CLAIMED,
                token=claim_token,
            )

        try:
            return claim_in_transaction(transaction)
        except Exception as error:
            raise ThresholdStoreError(
                "Failed to claim threshold notification."
            ) from error

    def mark_delivered(
        self,
        threshold_key: str,
        claim_token: str,
        message_id: str,
    ) -> bool:
        document = self.collection.document(threshold_key)
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
                    "delivered_message_id": message_id,
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
            raise ThresholdStoreError(
                "Failed to mark threshold notification as delivered."
            ) from error

    def release(
        self,
        threshold_key: str,
        claim_token: str,
    ) -> bool:
        document = self.collection.document(threshold_key)
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
                    "claim_token": firestore.DELETE_FIELD,
                    "lease_expires_at": now,
                },
            )

            return True

        try:
            return release_in_transaction(transaction)
        except Exception as error:
            raise ThresholdStoreError(
                "Failed to release threshold-notification claim."
            ) from error