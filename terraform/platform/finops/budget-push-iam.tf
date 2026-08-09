resource "google_service_account" "finops_budget_push_auth" {
  project      = var.management_project_id
  account_id   = "finops-budget-push-auth"
  display_name = "FinOps Budget Push Authentication"
  description  = "OIDC identity used by Pub/Sub to invoke the FinOps budget consumer."

  depends_on = [
    google_project_service.finops["iam.googleapis.com"],
  ]
}

resource "google_service_account_iam_member" "terraform_deployer_push_auth_user" {
  service_account_id = google_service_account.finops_budget_push_auth.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.terraform_deployer_service_account_email}"
}

resource "google_service_account_iam_member" "pubsub_push_token_creator" {
  service_account_id = google_service_account.finops_budget_push_auth.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_project_service_identity.pubsub.email}"
}

resource "google_cloud_run_v2_service_iam_member" "finops_budget_consumer_invoker" {
  project  = var.management_project_id
  location = var.region
  name     = module.finops_budget_consumer.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.finops_budget_push_auth.email}"
}