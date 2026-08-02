output "mig_name" {
  description = "Managed instance group name"
  value       = google_compute_region_instance_group_manager.this.name
}

output "instance_template_id" {
  description = "Instance template ID"
  value       = google_compute_instance_template.this.id
}

output "target_size" {
  description = "Configured target size"
  value       = google_compute_region_instance_group_manager.this.target_size
}
