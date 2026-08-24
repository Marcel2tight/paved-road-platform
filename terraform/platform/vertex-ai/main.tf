resource "google_project_service" "vertex_ai" {
  project = var.project_id
  service = var.vertex_ai_api

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_service_account" "vertex_runtime" {
  project      = var.project_id
  account_id   = var.runtime_service_account_id
  display_name = var.runtime_display_name
  description  = var.runtime_description

  depends_on = [
    google_project_service.vertex_ai,
  ]
}

resource "google_project_iam_member" "vertex_runtime_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vertex_runtime.email}"

  depends_on = [
    google_project_service.vertex_ai,
  ]
}
