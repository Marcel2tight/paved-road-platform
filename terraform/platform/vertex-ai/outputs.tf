output "vertex_ai_api" {
  description = "Vertex AI API governed by this Terraform root."
  value       = google_project_service.vertex_ai.service
}

output "runtime_service_account_email" {
  description = "Dedicated runtime identity authorized to invoke Vertex AI."
  value       = google_service_account.vertex_runtime.email
}

output "runtime_vertex_ai_role" {
  description = "Least-privilege Vertex AI role assigned to the runtime identity."
  value       = google_project_iam_member.vertex_runtime_user.role
}

output "approved_region" {
  description = "Approved region for the initial Development Vertex AI implementation."
  value       = var.region
}
