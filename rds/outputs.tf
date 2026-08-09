output "instance_id" {
  description = "Instance identifier"
  value       = aws_db_instance.instance.id
}

output "instance_arn" {
  description = "ARN of the instance"
  value       = aws_db_instance.instance.arn
}

output "instance_resource_id" {
  description = "Instance resource ID, used in IAM auth policies"
  value       = aws_db_instance.instance.resource_id
}

output "endpoint" {
  description = "Connection endpoint, address and port"
  value       = aws_db_instance.instance.endpoint
}

output "address" {
  description = "Hostname of the instance"
  value       = aws_db_instance.instance.address
}

output "port" {
  description = "Port the instance listens on"
  value       = aws_db_instance.instance.port
}

output "database_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.instance.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.instance.username
  sensitive   = true
}

output "master_user_secret_arn" {
  description = "ARN of the managed master user secret in Secrets Manager"
  value       = var.manage_master_user_password ? aws_db_instance.instance.master_user_secret[0].secret_arn : null
}

output "replica_endpoints" {
  description = "Map of replica identifier to endpoint"
  value       = { for k, v in aws_db_instance.replicas : k => v.endpoint }
}

output "replica_identifiers" {
  description = "List of replica identifiers"
  value       = [for v in aws_db_instance.replicas : v.identifier]
}

output "subnet_group_name" {
  description = "Name of the subnet group in use"
  value       = aws_db_instance.instance.db_subnet_group_name
}

output "parameter_group_name" {
  description = "Name of the parameter group in use"
  value       = aws_db_instance.instance.parameter_group_name
}

output "monitoring_role_arn" {
  description = "ARN of the Enhanced Monitoring role in use"
  value       = local.monitoring_role_arn
}
