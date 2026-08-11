output "service_name" {
  value = module.cloud_run_app.service_name
}

output "service_uri" {
  value = module.cloud_run_app.service_uri
}

output "service_location" {
  value = module.cloud_run_app.service_location
}

output "synthetic_probe_service_account_email" {
  value = google_service_account.synthetic_probe.email
}

output "synthetic_health_probe_job_name" {
  value = google_cloud_scheduler_job.synthetic_health_probe.name
}
