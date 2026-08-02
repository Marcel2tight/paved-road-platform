output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.this.endpoint
}

output "node_pool_name" {
  description = "GKE node pool name"
  value       = google_container_node_pool.this.name
}
