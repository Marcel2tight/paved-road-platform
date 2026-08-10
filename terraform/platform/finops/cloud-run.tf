module "finops_budget_consumer" {
  source = "../../modules/cloud-run"

  service_name          = "finops-budget-consumer"
  region                = var.region
  image                 = var.budget_consumer_image
  service_account_email = google_service_account.finops_budget_consumer.email

  container_port        = 8080
  min_instance_count    = 0
  max_instance_count    = 2
  cpu                   = "1"
  memory                = "512Mi"
  ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  allow_unauthenticated = false

  env_vars = {
    SERVICE_NAME                       = "finops-budget-consumer"
    FIRESTORE_COLLECTION               = "budget-events"
    THRESHOLD_NOTIFICATIONS_COLLECTION = "budget-threshold-notifications"
    EVENT_LEASE_DURATION_SECONDS       = "300"
  }

  secret_env_vars = {
    SLACK_WEBHOOK_URL = {
      secret  = google_secret_manager_secret.slack_webhook_url.secret_id
      version = "latest"
    }
  }

  startup_probe_path  = "/health"
  liveness_probe_path = "/health"

  labels = {
    environment = "shared"
    managed_by  = "terraform"
    platform    = "paved-road-platform"
    service     = "finops-budget-consumer"
    owner       = "platform-team"
    cost_center = "engineering"
  }

  depends_on = [
    google_project_service.finops["run.googleapis.com"],
    google_service_account_iam_member.terraform_deployer_budget_consumer_user,
    google_secret_manager_secret_iam_member.finops_budget_consumer_secret_accessor,
  ]
}