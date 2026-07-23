provider "google" {
  project = var.build_project_id
  region  = var.region
}

resource "google_artifact_registry_repository_iam_member" "promotion_reader" {
  for_each = var.promotion_deployer_service_accounts

  project    = var.build_project_id
  location   = var.region
  repository = var.build_repository
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value}"
}

resource "google_project_iam_member" "provenance_viewer" {
  for_each = var.promotion_deployer_service_accounts

  project = var.build_project_id
  role    = "roles/containeranalysis.occurrences.viewer"
  member  = "serviceAccount:${each.value}"
}
