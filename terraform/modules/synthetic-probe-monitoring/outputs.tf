output "log_metric_name" {
  description = "Name of the synthetic-probe failure log-based metric"
  value       = google_logging_metric.probe_failure.name
}

output "alert_policy_name" {
  description = "Fully qualified synthetic-probe failure alert policy name"
  value       = google_monitoring_alert_policy.probe_failure.name
}