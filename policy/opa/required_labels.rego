package terraform.required_labels

deny contains msg if {
    input.resource_type == "google_cloud_run_v2_service"

    not input.labels.environment

    msg := "Cloud Run service missing environment label"
}

deny contains msg if {
    input.resource_type == "google_cloud_run_v2_service"

    not input.labels.owner

    msg := "Cloud Run service missing owner label"
}

deny contains msg if {
    input.resource_type == "google_cloud_run_v2_service"

    not input.labels.cost_center

    msg := "Cloud Run service missing cost_center label"
}