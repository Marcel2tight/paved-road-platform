provider "google" {
  project               = var.management_project_id
  region                = var.region
  billing_project       = var.management_project_id
  user_project_override = true
}

provider "google-beta" {
  project = var.management_project_id
  region  = var.region
}