resource "google_pubsub_topic" "budget_notifications" {
  project      = var.management_project_id
  name         = var.budget_notification_topic_name
  kms_key_name = google_kms_crypto_key.pubsub.id

  labels = {
    environment = "management"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
    owner       = "platform-team"
    cost_center = "engineering"
    purpose     = "billing-budget-notifications"
  }

  depends_on = [
    google_project_service.finops["pubsub.googleapis.com"],
    google_kms_crypto_key_iam_member.pubsub_encrypter_decrypter,
  ]
}