variable "build_project_id" {
  description = "Project that owns the canonical build pipeline and artifact repository."
  type        = string
}

variable "region" {
  description = "Region containing the canonical Artifact Registry repository."
  type        = string
}

variable "build_repository" {
  description = "Canonical Artifact Registry repository receiving immutable images."
  type        = string
}

variable "builder_service_account_id" {
  description = "Account ID of the service account used by the GitHub image-build workflow."
  type        = string
  default     = "paved-road-builder"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.builder_service_account_id))
    error_message = "The builder service-account ID must be a valid Google Cloud service-account ID."
  }
}

variable "workload_identity_project_number" {
  description = "Numeric project number containing the GitHub Workload Identity Pool."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.workload_identity_project_number))
    error_message = "The Workload Identity project number must contain digits only."
  }
}

variable "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool trusted by the builder service account."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository authorized to impersonate the builder service account."
  type        = string

  validation {
    condition     = can(regex("^[^/[:space:]]+/[^/[:space:]]+$", var.github_repository))
    error_message = "The GitHub repository must use the owner/repository format."
  }
}