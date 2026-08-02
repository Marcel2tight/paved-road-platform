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

module "mig_app" {
  source = "../../../modules/mig"

  mig_name               = var.mig_name
  instance_name_prefix   = var.instance_name_prefix
  region                 = var.region
  machine_type           = var.machine_type
  source_image           = var.source_image
  disk_size_gb           = var.disk_size_gb
  disk_type              = var.disk_type
  network                = var.network
  subnetwork             = var.subnetwork
  service_account_email  = var.service_account_email
  service_account_scopes = var.service_account_scopes
  startup_script         = var.startup_script
  target_size            = var.target_size
  named_port_name        = var.named_port_name
  named_port             = var.named_port
  tags                   = var.tags
  labels                 = var.labels
  enable_shielded_vm     = var.enable_shielded_vm
}