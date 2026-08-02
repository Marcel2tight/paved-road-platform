resource "google_compute_instance_template" "this" {
  name_prefix  = "${var.instance_name_prefix}-"
  machine_type = var.machine_type
  region       = var.region
  tags         = var.tags

  labels = var.labels

  disk {
    source_image = var.source_image
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  metadata_startup_script = var.startup_script

  metadata = {
    block-project-ssh-keys = "TRUE"
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  shielded_instance_config {
    enable_secure_boot          = var.enable_shielded_vm
    enable_vtpm                 = var.enable_shielded_vm
    enable_integrity_monitoring = var.enable_shielded_vm
  }
}

resource "google_compute_region_instance_group_manager" "this" {
  name               = var.mig_name
  region             = var.region
  base_instance_name = var.instance_name_prefix

  version {
    instance_template = google_compute_instance_template.this.id
  }

  target_size = var.target_size

  named_port {
    name = var.named_port_name
    port = var.named_port
  }
}