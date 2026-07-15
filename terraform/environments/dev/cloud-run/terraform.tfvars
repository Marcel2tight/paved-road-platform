project_id            = "imposing-fx-413205"
region                = "us-central1"
service_name          = "backstage-acceptance-test"
image                 = "us-central1-docker.pkg.dev/imposing-fx-413205/paved-road-containers/paved-road-platform:v1.0.0"
service_account_email = "paved-road-sa@imposing-fx-413205.iam.gserviceaccount.com"

container_port        = 8080
min_instance_count    = 0
max_instance_count    = 2
cpu                   = "1"
memory                = "512Mi"
ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
allow_unauthenticated = false

env_vars = {
  ENVIRONMENT = "dev"
  PLATFORM    = "paved-road-platform"
}

labels = {
  environment = "dev"
  managed_by  = "backstage"
  platform    = "paved-road-platform"
  security    = "hardened"
  service     = "paved-road-dev-service"
  owner       = "platform-team"
  cost_center = "engineering"
}

