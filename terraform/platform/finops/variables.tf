variable "management_project_id" {
  description = "Project used to host centralized Paved Road FinOps resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.management_project_id))
    error_message = "The management project ID must be a valid Google Cloud project ID."
  }
}

variable "region" {
  description = "Default region for centralized platform resources."
  type        = string
  default     = "us-central1"
}

variable "billing_account_id" {
  description = "Google Cloud billing account governed by the Paved Road budget."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account_id))
    error_message = "The billing account ID must use the XXXXXX-XXXXXX-XXXXXX format."
  }
}

variable "budget_display_name" {
  description = "Display name of the billing-account-wide Paved Road budget."
  type        = string
  default     = "Paved Road Platform Budget"
}

variable "monthly_budget_amount" {
  description = "Monthly Paved Road Platform budget in USD."
  type        = number
  default     = 50

  validation {
    condition     = var.monthly_budget_amount > 0
    error_message = "The monthly budget amount must be greater than zero."
  }
}

variable "budget_notification_topic_name" {
  description = "Pub/Sub topic receiving programmatic Cloud Billing budget notifications."
  type        = string
  default     = "paved-road-billing-budget-notifications"
}

variable "budget_notification_subscription_name" {
  description = "Subscription receiving Cloud Billing budget notification events."
  type        = string
  default     = "paved-road-billing-budget-notifications-subscription"
}

variable "budget_notification_dead_letter_topic_name" {
  description = "Topic receiving budget events that exceed the delivery-attempt limit."
  type        = string
  default     = "paved-road-billing-budget-notifications-dlq"
}

variable "budget_notification_dead_letter_subscription_name" {
  description = "Subscription retaining failed budget events forwarded to the dead-letter topic."
  type        = string
  default     = "paved-road-billing-budget-notifications-dlq-subscription"
}

variable "budget_consumer_image" {
  description = "Immutable Artifact Registry image URI for the FinOps budget consumer."
  type        = string

  validation {
    condition = can(regex(
      "^us-central1-docker\\.pkg\\.dev/[^/]+/[^/]+/[^/@]+@sha256:[0-9a-f]{64}$",
      var.budget_consumer_image,
    ))
    error_message = "budget_consumer_image must be a us-central1 Artifact Registry URI pinned by sha256 digest."
  }
}

variable "terraform_deployer_service_account_email" {
  description = "Service-account email used by Terraform to deploy the FinOps infrastructure."
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.iam\\.gserviceaccount\\.com$", var.terraform_deployer_service_account_email))
    error_message = "terraform_deployer_service_account_email must be a valid Google service-account email."
  }
}