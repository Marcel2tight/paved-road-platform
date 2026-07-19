variable "project_id" {
  description = "GCP project that owns the monitoring resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev, stage, or prod"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, stage, or prod."
  }
}

variable "region" {
  description = "Region containing the Cloud Run service"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Cloud Run service monitored by the SLO"
  type        = string
}

variable "monitoring_service_id" {
  description = "Stable identifier for the Cloud Monitoring service"
  type        = string
}

variable "monitoring_service_display_name" {
  description = "Human-readable Cloud Monitoring service name"
  type        = string
}

variable "slo_id" {
  description = "Stable identifier for the availability SLO"
  type        = string
  default     = "availability-99-9"
}

variable "slo_display_name" {
  description = "Human-readable SLO name"
  type        = string
}

variable "slo_goal" {
  description = "Availability objective expressed as a value from 0 to 1"
  type        = number
  default     = 0.999

  validation {
    condition     = var.slo_goal > 0 && var.slo_goal < 1
    error_message = "SLO goal must be greater than 0 and less than 1."
  }
}

variable "rolling_period_days" {
  description = "Rolling compliance period in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 7, 14, 28, 30], var.rolling_period_days)
    error_message = "Rolling period must be one of 1, 7, 14, 28, or 30 days."
  }
}

variable "fast_burn_lookback" {
  description = "Lookback window used by the fast burn-rate alert"
  type        = string
  default     = "300s"
}

variable "fast_burn_threshold" {
  description = "Burn-rate threshold that opens the fast-burn incident"
  type        = number
  default     = 2.0

  validation {
    condition     = var.fast_burn_threshold > 0
    error_message = "Fast burn threshold must be greater than zero."
  }
}

variable "alert_email" {
  description = "Email address for environment-specific SLO notifications"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$", var.alert_email))
    error_message = "Alert email must be a valid email address."
  }
}

variable "notification_channel_display_name" {
  description = "Display name for the email notification channel"
  type        = string
}

variable "alert_policy_display_name" {
  description = "Display name for the fast burn-rate alert policy"
  type        = string
}

variable "documentation_content" {
  description = "Environment-specific incident-response instructions"
  type        = string
}

variable "user_labels" {
  description = "Labels applied to monitoring resources where supported"
  type        = map(string)
  default     = {}
}

variable "additional_notification_channels" {
  description = "Additional pre-existing notification channel resource names"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for channel in var.additional_notification_channels :
      can(regex("^projects/[^/]+/notificationChannels/[0-9]+$", channel))
    ])
    error_message = "Each additional notification channel must be a fully qualified Google Cloud notification-channel resource name."
  }
}
