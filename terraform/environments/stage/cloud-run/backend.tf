terraform {
  backend "gcs" {
    bucket = "marcel-paved-road-tfstate"
    prefix = "terraform/environments/stage/cloud-run/state"
  }
}
