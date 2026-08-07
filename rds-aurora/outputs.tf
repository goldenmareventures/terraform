output "cluster_id" {
  description = "Cluster identifier"
  value       = aws_rds_cluster.cluster.id
}

output "cluster_arn" {
  description = "ARN of the cluster"
  value       = aws_rds_cluster.cluster.arn
}

output "cluster_resource_id" {
  description = "Cluster resource ID, used in IAM auth policies"
  value       = aws_rds_cluster.cluster.cluster_resource_id
}

output "cluster_endpoint" {
  description = "Writer endpoint"
  value       = aws_rds_cluster.cluster.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint"
  value       = aws_rds_cluster.cluster.reader_endpoint
}

output "cluster_port" {
  description = "Port the cluster listens on"
  value       = aws_rds_cluster.cluster.port
}

output "database_name" {
  description = "Name of the initial database"
  value       = aws_rds_cluster.cluster.database_name
}

output "master_username" {
  description = "Master username"
  value       = aws_rds_cluster.cluster.master_username
  sensitive   = true
}

output "master_user_secret_arn" {
  description = "ARN of the managed master user secret in Secrets Manager"
  value       = var.manage_master_user_password ? aws_rds_cluster.cluster.master_user_secret[0].secret_arn : null
}

output "instance_endpoints" {
  description = "Map of instance identifier to endpoint"
  value       = { for k, v in aws_rds_cluster_instance.instances : k => v.endpoint }
}

output "instance_identifiers" {
  description = "List of instance identifiers"
  value       = [for v in aws_rds_cluster_instance.instances : v.identifier]
}

output "subnet_group_name" {
  description = "Name of the subnet group in use"
  value       = aws_rds_cluster.cluster.db_subnet_group_name
}

output "cluster_parameter_group_name" {
  description = "Name of the cluster parameter group in use"
  value       = aws_rds_cluster.cluster.db_cluster_parameter_group_name
}

output "monitoring_role_arn" {
  description = "ARN of the Enhanced Monitoring role in use"
  value       = local.monitoring_role_arn
}
