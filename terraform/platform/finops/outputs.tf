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

output "budget_notification_subscription_id" {
  description = "Fully qualified ID of the subscription receiving billing budget events."
  value       = google_pubsub_subscription.budget_notifications.id
}

output "budget_notification_dead_letter_topic_id" {
  description = "Fully qualified ID of the topic receiving repeatedly failed budget events."
  value       = google_pubsub_topic.budget_notifications_dead_letter.id
}

output "budget_notification_dead_letter_subscription_id" {
  description = "Fully qualified ID of the subscription retaining dead-lettered budget events."
  value       = google_pubsub_subscription.budget_notifications_dead_letter.id
}

output "finops_firestore_database_name" {
  description = "Firestore database used for FinOps budget-event deduplication."
  value       = google_firestore_database.finops_events.name
}

output "finops_budget_consumer_service_account_email" {
  description = "Runtime service-account email for the FinOps budget consumer."
  value       = google_service_account.finops_budget_consumer.email
}