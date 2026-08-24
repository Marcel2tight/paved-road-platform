variable "project_id" {
  description = "Development project hosting the governed Vertex AI foundation."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID."
  }
}

variable "region" {
  description = "Approved Google Cloud region for the Development Vertex AI foundation."
  type        = string
  default     = "us-central1"

  validation {
    condition     = var.region == "us-central1"
    error_message = "The initial Vertex AI foundation is restricted to us-central1."
  }
}

variable "vertex_ai_api" {
  description = "Vertex AI service API managed by Terraform."
  type        = string
  default     = "aiplatform.googleapis.com"

  validation {
    condition     = var.vertex_ai_api == "aiplatform.googleapis.com"
    error_message = "vertex_ai_api must remain aiplatform.googleapis.com."
  }
}

variable "runtime_service_account_id" {
  description = "Account ID for the dedicated Vertex AI application runtime identity."
  type        = string
  default     = "paved-road-vertex-runtime"

  validation {
    condition = (
      length(var.runtime_service_account_id) >= 6 &&
      length(var.runtime_service_account_id) <= 30 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.runtime_service_account_id))
    )
    error_message = "runtime_service_account_id must be a valid 6-30 character service-account ID."
  }
}

variable "runtime_display_name" {
  description = "Display name for the dedicated Vertex AI runtime identity."
  type        = string
  default     = "Paved Road Vertex AI Runtime"
}

variable "runtime_description" {
  description = "Description for the dedicated Vertex AI runtime identity."
  type        = string
  default     = "Keyless runtime identity used by the Paved Road Development AI service to invoke approved Vertex AI models."
}
