resource "google_logging_metric" "probe_failure" {
  project     = var.project_id
  name        = "paved_road_${var.environment}_synthetic_probe_failures"
  description = "Counts failed authenticated synthetic health-probe executions in ${var.environment}."

  filter = join(" AND ", [
    "resource.type=\"cloud_scheduler_job\"",
    "resource.labels.job_id=\"${var.scheduler_job_name}\"",
    "jsonPayload.@type=\"type.googleapis.com/google.cloud.scheduler.logging.AttemptFinished\"",
    "httpRequest.status>=400",
  ])

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    display_name = "Paved Road ${title(var.environment)} Synthetic Probe Failures"
  }
}

resource "time_sleep" "metric_propagation" {
  depends_on = [
    google_logging_metric.probe_failure
  ]

  create_duration = "90s"
}

resource "google_monitoring_alert_policy" "probe_failure" {
  depends_on = [
    time_sleep.metric_propagation
  ]

  project      = var.project_id
  display_name = "${title(var.environment)} Synthetic Probe Failure"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.notification_channels
  user_labels           = var.user_labels

  documentation {
    content   = replace(var.documentation_content, "\r\n", "\n")
    mime_type = "text/markdown"
  }

  conditions {
    display_name = "${title(var.environment)} synthetic health probe returned an error"

    condition_threshold {
      filter = join(" AND ", [
        "metric.type=\"logging.googleapis.com/user/${google_logging_metric.probe_failure.name}\"",
        "resource.type=\"cloud_scheduler_job\""
      ])

      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }
}