# Vertex AI Foundation

This Terraform root establishes the Development-only Vertex AI foundation for the Paved Road Platform.

It manages:

- Vertex AI API enablement
- A dedicated keyless Vertex AI application runtime service account
- The `roles/aiplatform.user` runtime grant
- Independent remote Terraform state

It does not manage:

- Stage or Production Vertex AI resources
- Model endpoints or tuned models
- Cloud Run application deployment
- User-managed service-account keys
- Global Vertex AI endpoints
- Preview models

Terraform state:

`gs://marcel-paved-road-tfstate/terraform/platform/vertex-ai/state/default.tfstate`

All application execution must use the dedicated runtime identity. The existing `paved-road-sa` deployment identity must not be used as the Vertex AI application runtime.
