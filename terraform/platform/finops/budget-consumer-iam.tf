resource "google_service_account" "finops_budget_consumer" {
  project      = var.management_project_id
  account_id   = "finops-budget-consumer"
  display_name = "FinOps Budget Consumer"
  description  = "Runtime identity for processing Cloud Billing budget events."

  depends_on = [
    google_project_service.finops["iam.googleapis.com"],
  ]
}

resource "google_service_account_iam_member" "terraform_deployer_budget_consumer_user" {
  service_account_id = google_service_account.finops_budget_consumer.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.terraform_deployer_service_account_email}"
}

resource "google_project_iam_member" "finops_budget_consumer_firestore_user" {
  project = var.management_project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.finops_budget_consumer.email}"
}