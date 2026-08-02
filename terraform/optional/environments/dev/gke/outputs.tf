output "cluster_name" {
  value = module.gke_app.cluster_name
}

output "cluster_endpoint" {
  value = module.gke_app.cluster_endpoint
}

output "node_pool_name" {
  value = module.gke_app.node_pool_name
}
