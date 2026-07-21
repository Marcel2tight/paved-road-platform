output "service_name" {
  value = module.cloud_run_app.service_name
}

output "service_uri" {
  value = module.cloud_run_app.service_uri
}

output "service_location" {
  value = module.cloud_run_app.service_location
}

output "synthetic_probe_service_account" {
  description = "Service account used by the Stage synthetic health probe"
  value       = google_service_account.synthetic_probe.email
}

output "synthetic_health_probe_job" {
  description = "Cloud Scheduler synthetic health-probe job name"
  value       = google_cloud_scheduler_job.synthetic_health_probe.name
}

output "synthetic_health_probe_uri" {
  description = "Stage endpoint called by the synthetic health probe"
  value       = "${module.cloud_run_app.service_uri}/health"
}

output "synthetic_probe_failure_metric" {
  description = "Stage synthetic-probe failure log-based metric"
  value       = module.synthetic_probe_monitoring.log_metric_name
}

output "synthetic_probe_failure_alert_policy" {
  description = "Stage synthetic-probe failure alert policy"
  value       = module.synthetic_probe_monitoring.alert_policy_name
}