# modules/ecs/cluster/outputs.tf
output "arn" {
  description = "ARN of the cluster. Pass this to the ecs/service module."
  value       = aws_ecs_cluster.cluster.arn
}

output "id" {
  description = "ID of the cluster"
  value       = aws_ecs_cluster.cluster.id
}

output "name" {
  description = "Name of the cluster, used in CloudWatch metric dimensions"
  value       = aws_ecs_cluster.cluster.name
}
