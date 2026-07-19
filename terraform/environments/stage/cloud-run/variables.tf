variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "image" {
  description = "Container image"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Cloud Run"
  type        = string
}

variable "container_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "min_instance_count" {
  description = "Minimum instances"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum instances"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU limit"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "ingress" {
  description = "Ingress policy"
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}

variable "allow_unauthenticated" {
  description = "Allow public access"
  type        = bool
  default     = false
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels"
  type        = map(string)
  default     = {}
}

variable "alert_email" {
  description = "Email address for Staging SLO alerts"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}
