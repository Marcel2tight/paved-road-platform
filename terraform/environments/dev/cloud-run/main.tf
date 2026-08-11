terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "cloud_run_app" {
  source = "../../../modules/cloud-run"

  service_name          = var.service_name
  region                = var.region
  image                 = var.image
  service_account_email = var.service_account_email
  container_port        = var.container_port
  min_instance_count    = var.min_instance_count
  max_instance_count    = var.max_instance_count
  cpu                   = var.cpu
  memory                = var.memory
  ingress               = var.ingress
  allow_unauthenticated = var.allow_unauthenticated
  env_vars              = var.env_vars
  labels                = var.labels
}

resource "google_service_account" "synthetic_probe" {
  project      = var.project_id
  account_id   = "paved-road-dev-probe"
  display_name = "Paved Road Dev Synthetic Probe"
  description  = "OIDC identity used by Cloud Scheduler to probe the Dev Cloud Run service."
}

import {
  to = google_service_account.synthetic_probe
  id = "projects/imposing-fx-413205/serviceAccounts/paved-road-dev-probe@imposing-fx-413205.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "synthetic_probe_deployer_user" {
  service_account_id = google_service_account.synthetic_probe.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:paved-road-sa@imposing-fx-413205.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "synthetic_probe_deployer_admin" {
  service_account_id = google_service_account.synthetic_probe.name
  role               = "roles/iam.serviceAccountAdmin"
  member             = "serviceAccount:paved-road-sa@imposing-fx-413205.iam.gserviceaccount.com"
}

resource "google_cloud_run_v2_service_iam_member" "synthetic_probe_invoker" {
  project  = var.project_id
  name     = module.cloud_run_app.service_name
  location = module.cloud_run_app.service_location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.synthetic_probe.email}"
}

resource "google_cloud_scheduler_job" "synthetic_health_probe" {
  project     = var.project_id
  region      = var.region
  name        = "${var.service_name}-health-probe"
  description = "Authenticated internal health probe for the Dev Cloud Run service."
  schedule    = "*/5 * * * *"
  time_zone   = "Etc/UTC"

  attempt_deadline = "30s"

  http_target {
    uri         = "${module.cloud_run_app.service_uri}/health"
    http_method = "GET"

    oidc_token {
      service_account_email = google_service_account.synthetic_probe.email
      audience              = module.cloud_run_app.service_uri
    }
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "30s"
    max_doublings        = 2
  }

  depends_on = [
    google_cloud_run_v2_service_iam_member.synthetic_probe_invoker,
    google_service_account_iam_member.synthetic_probe_deployer_user,
    google_service_account_iam_member.synthetic_probe_deployer_admin
  ]
}

# Trigger PR validation workflow
# Trigger dev deployment
# Test Slack notifications