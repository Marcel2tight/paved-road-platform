terraform {
  backend "gcs" {
    bucket = "marcel-paved-road-tfstate"
    prefix = "terraform/platform/promotion-iam/state"
  }
}
