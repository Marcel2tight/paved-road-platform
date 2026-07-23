output "build_project_id" {
  description = "Project containing the canonical build artifacts."
  value       = var.build_project_id
}

output "build_repository" {
  description = "Canonical Artifact Registry repository governed by this root."
  value       = var.build_repository
}

output "promotion_deployer_service_accounts" {
  description = "Deployer service accounts granted artifact and provenance read access."
  value       = sort(tolist(var.promotion_deployer_service_accounts))
}
