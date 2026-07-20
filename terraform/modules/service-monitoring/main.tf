resource "google_monitoring_service" "this" {
  project      = var.project_id
  service_id   = var.monitoring_service_id
  display_name = var.monitoring_service_display_name

  basic_service {
    service_type = "CLOUD_RUN"

    service_labels = {
      location     = var.region
      service_name = var.cloud_run_service_name
    }
  }
}

resource "google_monitoring_slo" "availability" {
  project      = var.project_id
  service      = google_monitoring_service.this.service_id
  slo_id       = var.slo_id
  display_name = var.slo_display_name

  goal                = var.slo_goal
  rolling_period_days = var.rolling_period_days

  basic_sli {
    availability {
      enabled = true
    }
  }
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = var.notification_channel_display_name
  type         = "email"
  enabled      = true

  labels = {
    email_address = var.alert_email
  }

  user_labels = var.user_labels
}

resource "google_monitoring_alert_policy" "fast_burn" {
  project      = var.project_id
  display_name = var.alert_policy_display_name
  combiner     = "OR"
  enabled      = true

  notification_channels = concat(
    [google_monitoring_notification_channel.email.name],
    var.additional_notification_channels
  )

  user_labels = var.user_labels

  documentation {
    content   = replace(var.documentation_content, "\r\n", "\n")
    mime_type = "text/markdown"
  }

  conditions {
    display_name = var.alert_policy_display_name

    condition_threshold {
      filter = "select_slo_burn_rate(\"${google_monitoring_slo.availability.name}\", \"${var.fast_burn_lookback}\")"

      comparison      = "COMPARISON_GT"
      threshold_value = var.fast_burn_threshold
      duration        = "0s"

      trigger {
        count = 1
      }
    }
  }
}
