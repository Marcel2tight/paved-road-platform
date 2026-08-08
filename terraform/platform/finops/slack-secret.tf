resource "google_secret_manager_secret" "slack_webhook_url" {
  project   = var.management_project_id
  secret_id = "finops-slack-webhook-url"

  replication {
    auto {}
  }

  labels = {
    environment = "shared"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
    service     = "finops-budget-consumer"
    owner       = "platform-team"
    cost_center = "engineering"
  }

  depends_on = [
    google_project_service.finops["secretmanager.googleapis.com"],
  ]
}

resource "google_secret_manager_secret_iam_member" "finops_budget_consumer_secret_accessor" {
  project   = var.management_project_id
  secret_id = google_secret_manager_secret.slack_webhook_url.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.finops_budget_consumer.email}"
}