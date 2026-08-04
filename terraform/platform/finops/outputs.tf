output "budget_name" {
  description = "Fully qualified name of the managed billing budget."
  value       = google_billing_budget.paved_road.name
}

output "budget_display_name" {
  description = "Display name of the managed billing budget."
  value       = google_billing_budget.paved_road.display_name
}

output "budget_notification_topic_id" {
  description = "Fully qualified Pub/Sub topic used for budget notifications."
  value       = google_pubsub_topic.budget_notifications.id
}

output "management_project_id" {
  description = "Project hosting the centralized FinOps resources."
  value       = var.management_project_id
}