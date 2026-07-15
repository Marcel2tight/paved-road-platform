project_id              = "imposing-fx-413205"
cluster_name            = "paved-road-dev-gke"
node_pool_name          = "paved-road-dev-pool"
region                  = "us-central1"
network                 = "default"
subnetwork              = "default"
machine_type            = "e2-medium"
node_count              = 1
service_account_email   = "paved-road-sa@imposing-fx-413205.iam.gserviceaccount.com"
deletion_protection     = true
enable_private_nodes    = true
enable_private_endpoint = false
master_ipv4_cidr_block  = "172.16.0.0/28"
enable_shielded_nodes   = true
enable_network_policy   = true

oauth_scopes = [
  "https://www.googleapis.com/auth/logging.write",
  "https://www.googleapis.com/auth/monitoring"
]

tags = [
  "paved-road",
  "gke"
]

labels = {
  environment = "dev"
  managed_by  = "terraform"
  platform    = "paved-road-platform"
  security    = "hardened"
  service     = "paved-road-dev-gke"
  owner       = "platform-team"
}
