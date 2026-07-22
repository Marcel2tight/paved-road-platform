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

module "service_monitoring" {
  source = "../../../modules/service-monitoring"

  project_id             = var.project_id
  environment            = "prod"
  region                 = var.region
  cloud_run_service_name = var.service_name

  monitoring_service_id           = "paved-road-prod-cloud-run"
  monitoring_service_display_name = "Paved Road Production Cloud Run Service"

  slo_id           = "availability-99-9"
  slo_display_name = "Cloud Run Production Availability SLO"
  slo_goal         = 0.999

  rolling_period_days = 30
  fast_burn_lookback  = "300s"
  fast_burn_threshold = 2.0

  alert_email                       = var.alert_email
  notification_channel_display_name = "Paved Road Production SLO Alerts"
  alert_policy_display_name         = "Production SLO Fast Burn Alert (5m)"

  # Pre-authorized Production Slack notification channel
  additional_notification_channels = [
    "projects/paved-road-prod-413205/notificationChannels/2404726903934443147"
  ]

  documentation_content = <<-EOT
    ## Production SLO fast-burn response

    The Production Cloud Run availability SLO is consuming its error budget faster than the configured threshold.

    1. Inspect the Cloud Run service:

       `gcloud run services describe ${var.service_name} --region=${var.region} --project=${var.project_id}`

    2. Review recent request and application logs in Cloud Logging.

    3. Check the latest ready revision and recent deployment history.

    4. Validate the Production promotion workflow in GitHub Actions.

    5. If a recent revision caused the incident, shift traffic back to the last healthy revision or redeploy the previous verified image.
  EOT

  user_labels = {
    environment = "prod"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
  }
}

resource "google_service_account" "synthetic_probe" {
  project      = var.project_id
  account_id   = "paved-road-prod-probe"
  display_name = "Paved Road Production Synthetic Probe"
  description  = "OIDC identity used by Cloud Scheduler to probe the Production Cloud Run service."
}

resource "google_service_account_iam_member" "synthetic_probe_deployer_user" {
  service_account_id = google_service_account.synthetic_probe.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:paved-road-deployer@paved-road-prod-413205.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "synthetic_probe_deployer_admin" {
  service_account_id = google_service_account.synthetic_probe.name
  role               = "roles/iam.serviceAccountAdmin"
  member             = "serviceAccount:paved-road-deployer@paved-road-prod-413205.iam.gserviceaccount.com"
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
  description = "Authenticated synthetic health probe for the Production Cloud Run service."
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

module "synthetic_probe_monitoring" {
  source = "../../../modules/synthetic-probe-monitoring"

  project_id         = var.project_id
  environment        = "prod"
  scheduler_job_name = google_cloud_scheduler_job.synthetic_health_probe.name

  notification_channels = [
    module.service_monitoring.notification_channel_name,
    "projects/paved-road-prod-413205/notificationChannels/2404726903934443147"
  ]

  documentation_content = <<-EOT
    ## Production synthetic probe failure

    The authenticated Cloud Scheduler health probe for the Production Cloud Run service returned an HTTP error.

    1. Inspect the Scheduler job:

       `gcloud scheduler jobs describe ${google_cloud_scheduler_job.synthetic_health_probe.name} --location=${var.region} --project=${var.project_id}`

    2. Review recent Scheduler execution logs:

       `gcloud logging read 'resource.type="cloud_scheduler_job" AND resource.labels.job_id="${google_cloud_scheduler_job.synthetic_health_probe.name}"' --freshness=30m --project=${var.project_id}`

    3. Inspect the Cloud Run service:

       `gcloud run services describe ${var.service_name} --region=${var.region} --project=${var.project_id}`

    4. Confirm that the probe identity retains service-specific `roles/run.invoker`.

    5. Check the `/health` endpoint and the latest ready Cloud Run revision.

    6. If a recent deployment caused the failure, redeploy the last verified immutable image.
  EOT

  user_labels = {
    environment = "prod"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
  }
}