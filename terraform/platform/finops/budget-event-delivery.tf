resource "google_pubsub_topic" "budget_notifications_dead_letter" {
  project      = var.management_project_id
  name         = var.budget_notification_dead_letter_topic_name
  kms_key_name = google_kms_crypto_key.pubsub.id

  labels = {
    environment = "management"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
    owner       = "platform-team"
    cost_center = "engineering"
    purpose     = "billing-budget-notifications-dlq"
  }

  depends_on = [
    google_project_service.finops["pubsub.googleapis.com"],
    google_kms_crypto_key_iam_member.pubsub_encrypter_decrypter,
  ]
}

resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  project = var.management_project_id
  topic   = google_pubsub_topic.budget_notifications_dead_letter.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

resource "google_pubsub_subscription" "budget_notifications" {
  project = var.management_project_id
  name    = var.budget_notification_subscription_name
  topic   = google_pubsub_topic.budget_notifications.id

  ack_deadline_seconds         = 30
  message_retention_duration   = "604800s"
  retain_acked_messages        = false
  enable_message_ordering      = false
  enable_exactly_once_delivery = true

  expiration_policy {
    ttl = ""
  }

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.budget_notifications_dead_letter.id
    max_delivery_attempts = 5
  }

  labels = {
    environment = "management"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
    owner       = "platform-team"
    cost_center = "engineering"
    purpose     = "billing-budget-event-delivery"
  }

  depends_on = [
    google_pubsub_topic_iam_member.dead_letter_publisher,
  ]
}

resource "google_pubsub_subscription_iam_member" "budget_notifications_subscriber" {
  project      = var.management_project_id
  subscription = google_pubsub_subscription.budget_notifications.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

resource "google_pubsub_subscription" "budget_notifications_dead_letter" {
  project = var.management_project_id
  name    = var.budget_notification_dead_letter_subscription_name
  topic   = google_pubsub_topic.budget_notifications_dead_letter.id

  ack_deadline_seconds       = 30
  message_retention_duration = "604800s"
  retain_acked_messages      = false

  expiration_policy {
    ttl = ""
  }

  labels = {
    environment = "management"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
    owner       = "platform-team"
    cost_center = "engineering"
    purpose     = "billing-budget-notifications-dlq-retention"
  }
}