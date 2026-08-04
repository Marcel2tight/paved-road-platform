resource "google_pubsub_topic" "budget_notifications" {
  project = var.management_project_id
  name    = var.budget_notification_topic_name

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
  ]
}