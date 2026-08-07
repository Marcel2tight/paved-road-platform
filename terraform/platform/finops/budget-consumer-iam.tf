resource "google_service_account" "finops_budget_consumer" {
  project      = var.management_project_id
  account_id   = "finops-budget-consumer"
  display_name = "FinOps Budget Consumer"
  description  = "Runtime identity for processing Cloud Billing budget events."

  depends_on = [
    google_project_service.finops["iam.googleapis.com"],
  ]
}

resource "google_project_iam_member" "finops_budget_consumer_firestore_user" {
  project = var.management_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.finops_budget_consumer.email}"
}