output "monitoring_service_name" {
  description = "Fully qualified Cloud Monitoring service resource name"
  value       = google_monitoring_service.this.name
}

output "monitoring_service_id" {
  description = "Stable identifier of the Cloud Monitoring service"
  value       = google_monitoring_service.this.service_id
}

output "slo_name" {
  description = "Fully qualified availability SLO resource name"
  value       = google_monitoring_slo.availability.name
}

output "slo_id" {
  description = "Stable identifier of the availability SLO"
  value       = google_monitoring_slo.availability.slo_id
}

output "notification_channel_name" {
  description = "Fully qualified email notification channel resource name"
  value       = google_monitoring_notification_channel.email.name
}

output "alert_policy_name" {
  description = "Fully qualified fast-burn alert policy resource name"
  value       = google_monitoring_alert_policy.fast_burn.name
}
