# modules/ecs/service/outputs.tf
output "service_name" {
  description = "Name of the ECS service, or null when create_service is false"
  value       = local.service_name
}

output "service_id" {
  description = "ID of the ECS service, or null when create_service is false"
  value       = local.service_id
}

output "task_definition_arn" {
  description = "ARN of the task definition revision"
  value       = aws_ecs_task_definition.task.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.task.family
}

output "task_definition_revision" {
  description = "Revision number of the task definition"
  value       = aws_ecs_task_definition.task.revision
}

output "security_group_id" {
  description = "ID of the managed security group, or null when the module did not create one"
  value       = one(aws_security_group.service[*].id)
}

output "security_group_ids" {
  description = "Every security group attached to the tasks"
  value       = local.security_group_ids
}

output "execution_role_arn" {
  description = "ARN of the execution role in use, created or supplied"
  value       = local.execution_role_arn
}

output "execution_role_name" {
  description = "Name of the created execution role, or null when one was supplied"
  value       = one(aws_iam_role.execution[*].name)
}

output "task_role_arn" {
  description = "ARN of the task role in use, created or supplied"
  value       = local.task_role_arn
}

output "task_role_name" {
  description = "Name of the created task role, or null when one was supplied"
  value       = one(aws_iam_role.task[*].name)
}

output "log_group_name" {
  description = "Name of the created log group, or null when the module did not create one"
  value       = one(aws_cloudwatch_log_group.task[*].name)
}

output "autoscaling_target_resource_id" {
  description = "Resource ID of the autoscaling target, for extra scaling policies"
  value       = one(aws_appautoscaling_target.service[*].resource_id)
}
