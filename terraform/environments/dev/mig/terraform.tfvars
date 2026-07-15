project_id            = "imposing-fx-413205"
region                = "us-central1"
mig_name              = "paved-road-dev-mig"
instance_name_prefix  = "paved-road-dev-vm"
machine_type          = "e2-medium"
source_image          = "projects/debian-cloud/global/images/family/debian-12"
disk_size_gb          = 20
disk_type             = "pd-balanced"
network               = "default"
subnetwork            = "default"
assign_public_ip      = false
service_account_email = "paved-road-sa@imposing-fx-413205.iam.gserviceaccount.com"
target_size           = 1
named_port_name       = "http"
named_port            = 80
enable_shielded_vm    = true

service_account_scopes = [
  "https://www.googleapis.com/auth/logging.write",
  "https://www.googleapis.com/auth/monitoring.write"
]

startup_script = <<-EOT
#!/bin/bash
apt-get update
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx
echo "Hello from the hardened Day 7 MIG template" > /var/www/html/index.html
EOT

tags = [
  "paved-road"
]

labels = {
  environment = "dev"
  managed_by  = "terraform"
  platform    = "paved-road-platform"
  security    = "hardened"
  service     = "paved-road-dev-mig"
  owner       = "platform-team"
}
