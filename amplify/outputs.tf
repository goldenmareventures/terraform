output "app_id" {
  description = "Amplify app ID"
  value       = aws_amplify_app.app.id
}

output "app_arn" {
  description = "Amplify app ARN"
  value       = aws_amplify_app.app.arn
}

output "default_domain" {
  description = "Default Amplify domain"
  value       = aws_amplify_app.app.default_domain
}

output "branch_names" {
  description = "Map of branch names"
  value       = { for k, v in aws_amplify_branch.branches : k => v.branch_name }
}

output "domain_association_arn" {
  description = "Domain association ARN"
  value       = try(aws_amplify_domain_association.domain[0].arn, null)
}
