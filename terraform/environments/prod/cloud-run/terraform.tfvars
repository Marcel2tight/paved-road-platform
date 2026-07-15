project_id   = "paved-road-prod-413205"
region       = "us-central1"
service_name = "paved-road-prod-app"

# Temporary bootstrap image.
# Replace after paved-road-platform:v1.0.0 is built and published.
image = "us-central1-docker.pkg.dev/paved-road-prod-413205/paved-road-containers/paved-road-platform:v1.0.0"

service_account_email = "paved-road-runtime@paved-road-prod-413205.iam.gserviceaccount.com"

container_port     = 8080
min_instance_count = 0
max_instance_count = 2

cpu    = "1"
memory = "512Mi"

ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
allow_unauthenticated = false

env_vars = {
  ENVIRONMENT = "prod"
  PLATFORM    = "paved-road-platform"
}

labels = {
  environment = "prod"
  managed_by  = "terraform"
  platform    = "paved-road-platform"
  security    = "hardened"
  service     = "paved-road-prod-app"
  owner       = "platform-team"
  cost_center = "engineering"
}