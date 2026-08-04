resource "google_billing_budget" "paved_road" {
  billing_account = var.billing_account_id
  display_name    = var.budget_display_name

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_amount)
    }
  }

  budget_filter {
    calendar_period        = "MONTH"
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic                     = google_pubsub_topic.budget_notifications.id
    schema_version                   = "1.0"
    disable_default_iam_recipients   = false
    monitoring_notification_channels = []
  }

  depends_on = [
    google_project_service.finops["billingbudgets.googleapis.com"],
    google_pubsub_topic.budget_notifications,
  ]
}