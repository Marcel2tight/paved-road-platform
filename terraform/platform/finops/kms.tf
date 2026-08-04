resource "google_kms_key_ring" "finops" {
  project  = var.management_project_id
  name     = "paved-road-finops"
  location = "global"

  depends_on = [
    google_project_service.finops["cloudkms.googleapis.com"],
  ]
}

resource "google_kms_crypto_key" "pubsub" {
  name            = "pubsub-budget-notifications"
  key_ring        = google_kms_key_ring.finops.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service_identity" "pubsub" {
  provider = google-beta

  project = var.management_project_id
  service = "pubsub.googleapis.com"

  depends_on = [
    google_project_service.finops["pubsub.googleapis.com"],
  ]
}

resource "google_kms_crypto_key_iam_member" "pubsub_encrypter_decrypter" {
  crypto_key_id = google_kms_crypto_key.pubsub.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.pubsub.email}"
}