output "cluster_name" {
  value = module.gke.name
}

output "endpoint" {
  value = module.gke.endpoint
  sensitive = true
}
