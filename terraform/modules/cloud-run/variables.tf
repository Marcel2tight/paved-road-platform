variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "image" {
  description = "Container image to deploy"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service"
  type        = string
}

variable "container_port" {
  description = "Container listening port"
  type        = number
  default     = 8080
}

variable "min_instance_count" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "CPU limit for the container"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "ingress" {
  description = "Ingress setting for Cloud Run"
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}

variable "allow_unauthenticated" {
  description = "Whether to allow unauthenticated access"
  type        = bool
  default     = false
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret Manager-backed environment variables for the container."
  type = map(object({
    secret  = string
    version = string
  }))
  default = {}
}

variable "startup_probe_path" {
  description = "HTTP path used for the optional startup probe."
  type        = string
  default     = null
  nullable    = true
}

variable "liveness_probe_path" {
  description = "HTTP path used for the optional liveness probe."
  type        = string
  default     = null
  nullable    = true
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)

  validation {
    condition = (
      contains(keys(var.labels), "environment") &&
      contains(keys(var.labels), "managed_by") &&
      contains(keys(var.labels), "platform") &&
      contains(keys(var.labels), "owner") &&
      contains(keys(var.labels), "cost_center")
    )

    error_message = "Required labels missing."
  }
}
