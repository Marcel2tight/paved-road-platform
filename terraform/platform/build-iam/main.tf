provider "google" {
  project = var.build_project_id
  region  = var.region
}

resource "google_service_account" "paved_road_builder" {
  project      = var.build_project_id
  account_id   = var.builder_service_account_id
  display_name = "Paved Road Image Builder"
  description  = "Builds, signs, attests, and publishes immutable Paved Road container images."
}

resource "google_service_account_iam_member" "github_workload_identity_user" {
  service_account_id = google_service_account.paved_road_builder.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${var.workload_identity_project_number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
}

resource "google_artifact_registry_repository_iam_member" "builder_writer" {
  project    = var.build_project_id
  location   = var.region
  repository = var.build_repository
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.paved_road_builder.email}"
}

resource "google_project_iam_member" "cloud_build_editor" {
  project = var.build_project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.paved_road_builder.email}"
}

resource "google_project_iam_member" "service_usage_consumer" {
  project = var.build_project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.paved_road_builder.email}"
}

# gcloud builds submit checks whether the default Cloud Build
# staging bucket exists by listing buckets in the build project.
resource "google_project_iam_member" "cloud_build_bucket_viewer" {
  project = var.build_project_id
  role    = "roles/storage.bucketViewer"
  member  = "serviceAccount:${google_service_account.paved_road_builder.email}"
}

resource "google_storage_bucket_iam_member" "cloud_build_source_bucket_reader" {
  bucket = "${var.build_project_id}_cloudbuild"
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.paved_road_builder.email}"
}

resource "google_storage_bucket_iam_member" "cloud_build_source_object_admin" {
  bucket = "${var.build_project_id}_cloudbuild"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.paved_road_builder.email}"
}

resource "google_service_account_iam_member" "builder_can_act_as_cloud_build_runtime" {
  service_account_id = "projects/${var.build_project_id}/serviceAccounts/915035381641-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.paved_road_builder.email}"
}