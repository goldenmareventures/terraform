# modules/iam/user/outputs.tf
output "user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.user.name
}

output "user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.user.arn
}

output "access_key_id" {
  description = "Access key ID (if created)"
  value       = var.create_access_key ? aws_iam_access_key.user_key[0].id : null
}

output "secret_access_key" {
  description = "Secret access key (sensitive, if created)"
  value       = var.create_access_key ? aws_iam_access_key.user_key[0].secret : null
  sensitive   = true
}
