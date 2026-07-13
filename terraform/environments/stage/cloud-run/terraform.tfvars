project_id            = "paved-road-stage-413205"
region                = "us-central1"
service_name          = "paved-road-stage-app"
image                 = "us-docker.pkg.dev/cloudrun/container/hello"
service_account_email = "paved-road-runtime@paved-road-stage-413205.iam.gserviceaccount.com"

container_port        = 8080
min_instance_count    = 0
max_instance_count    = 2
cpu                   = "1"
memory                = "512Mi"
ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
allow_unauthenticated = false

env_vars = {
  ENVIRONMENT = "stage"
  PLATFORM    = "paved-road-engine"
}

labels = {
  environment = "stage"
  managed_by  = "terraform"
  platform    = "paved-road-engine"
  security    = "hardened"
  service     = "paved-road-stage-app"
  owner       = "platform-team"
  cost_center = "engineering"
}
