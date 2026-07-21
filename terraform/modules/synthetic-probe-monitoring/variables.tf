variable "project_id" {
  description = "GCP project containing the synthetic probe"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["stage", "prod"], var.environment)
    error_message = "Environment must be stage or prod."
  }
}

variable "scheduler_job_name" {
  description = "Cloud Scheduler job monitored for failed executions"
  type        = string
}

variable "notification_channels" {
  description = "Cloud Monitoring notification channel resource names"
  type        = list(string)

  validation {
    condition = alltrue([
      for channel in var.notification_channels :
      can(regex("^projects/[^/]+/notificationChannels/[0-9]+$", channel))
    ])
    error_message = "Notification channels must be fully qualified resource names."
  }
}

variable "documentation_content" {
  description = "Incident-response documentation attached to the alert"
  type        = string
}

variable "user_labels" {
  description = "Labels applied to supported monitoring resources"
  type        = map(string)
  default     = {}
}