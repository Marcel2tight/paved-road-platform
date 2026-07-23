variable "build_project_id" {
  description = "Project that owns the canonical build artifact repository and provenance metadata."
  type        = string
}

variable "region" {
  description = "Region containing the canonical Artifact Registry repository."
  type        = string
}

variable "build_repository" {
  description = "Canonical Artifact Registry repository used for immutable promotion."
  type        = string
}

variable "promotion_deployer_service_accounts" {
  description = "Stage and Production deployer service accounts permitted to read and verify promoted artifacts."
  type        = set(string)

  validation {
    condition = (
      length(var.promotion_deployer_service_accounts) > 0 &&
      alltrue([
        for service_account in var.promotion_deployer_service_accounts :
        can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.iam\\.gserviceaccount\\.com$", service_account))
      ])
    )
    error_message = "Each promotion deployer must be a valid Google Cloud service-account email address."
  }
}
