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

module "gke_app" {
  source = "../../../modules/gke"

  project_id              = var.project_id
  cluster_name            = var.cluster_name
  node_pool_name          = var.node_pool_name
  region                  = var.region
  network                 = var.network
  subnetwork              = var.subnetwork
  machine_type            = var.machine_type
  node_count              = var.node_count
  service_account_email   = var.service_account_email
  oauth_scopes            = var.oauth_scopes
  tags                    = var.tags
  labels                  = var.labels
  deletion_protection     = var.deletion_protection
  enable_private_nodes    = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  enable_shielded_nodes   = var.enable_shielded_nodes
  enable_network_policy   = var.enable_network_policy
}