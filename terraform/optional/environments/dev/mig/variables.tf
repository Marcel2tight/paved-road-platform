variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Deployment region"
  type        = string
}

variable "mig_name" {
  description = "Managed instance group name"
  type        = string
}

variable "instance_name_prefix" {
  description = "Base instance name prefix"
  type        = string
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "Source image for instances"
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "disk_size_gb" {
  description = "Boot disk size"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "network" {
  description = "VPC network"
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork"
  type        = string
}

variable "assign_public_ip" {
  description = "Whether to assign public IPs"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email"
  type        = string
}

variable "service_account_scopes" {
  description = "Service account scopes"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
}

variable "startup_script" {
  description = "VM startup script"
  type        = string
  default     = ""
}

variable "target_size" {
  description = "Desired number of instances"
  type        = number
  default     = 1
}

variable "named_port_name" {
  description = "Named port label"
  type        = string
  default     = "http"
}

variable "named_port" {
  description = "Named port value"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Network tags"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels"
  type        = map(string)
  default     = {}
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM features"
  type        = bool
  default     = true
}
