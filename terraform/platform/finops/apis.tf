locals {
  required_services = toset([
    "bigquery.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "pubsub.googleapis.com",
  ])
}

resource "google_project_service" "finops" {
  for_each = local.required_services

  project            = var.management_project_id
  service            = each.value
  disable_on_destroy = false
}