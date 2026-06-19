output "cluster_name" {
  description = "Tên EKS Cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint của EKS Cluster"
  value       = module.eks.cluster_endpoint
}
