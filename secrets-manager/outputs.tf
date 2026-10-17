output "secret_arns" {
  description = "Secret ARNs keyed by the secrets map key"
  value       = { for k, s in aws_secretsmanager_secret.secret : k => s.arn }
}
