variable "mig_name" {
  description = "Name of the managed instance group"
  type        = string
}

variable "instance_name_prefix" {
  description = "Prefix for instances created by the MIG"
  type        = string
}

variable "region" {
  description = "Region for the MIG"
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-medium"
}

variable "source_image" {
  description = "Source image for the boot disk"
  type        = string
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "pd-balanced"
}

variable "network" {
  description = "VPC network name or self link"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name or self link"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for VM instances"
  type        = string
}

variable "service_account_scopes" {
  description = "Scopes for the VM service account"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write"]
}

variable "startup_script" {
  description = "Startup script for VM initialization"
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
  description = "Network tags for instances"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to instances"
  type        = map(string)
  default     = {}
}

variable "enable_shielded_vm" {
  description = "Whether to enable Shielded VM features"
  type        = bool
  default     = true
}