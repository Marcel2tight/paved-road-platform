terraform {
  backend "gcs" {
    bucket = "marcel-paved-road-tfstate"
    prefix = "terraform/platform/finops/state"
  }
}