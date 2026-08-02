resource "google_container_cluster" "this" {
  # checkov:skip=CKV_GCP_65:Google Groups for GKE RBAC requires a Google Workspace or Cloud Identity organization; this standalone project has no organization parent.
  # checkov:skip=CKV_GCP_69:The default node pool is removed; Workload Identity is enabled at cluster level and GKE_METADATA is enforced on the separately managed node pool.

  name     = var.cluster_name
  location = var.region

  deletion_protection = var.deletion_protection

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {}

  enable_intranode_visibility = true

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  release_channel {
    channel = "REGULAR"
  }

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  network_policy {
    enabled = var.enable_network_policy
  }

  resource_labels = var.labels
}

resource "google_container_node_pool" "this" {
  name     = var.node_pool_name
  location = var.region
  cluster  = google_container_cluster.this.name

  node_count = var.node_count

  node_config {
    machine_type    = var.machine_type
    service_account = var.service_account_email
    oauth_scopes    = var.oauth_scopes
    tags            = var.tags
    labels          = var.labels

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    dynamic "shielded_instance_config" {
      for_each = var.enable_shielded_nodes ? [1] : []
      content {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}