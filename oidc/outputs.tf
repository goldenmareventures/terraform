output "arn" {
  description = "ARN of the OIDC provider, for the Federated principal of a trust policy"
  value       = aws_iam_openid_connect_provider.provider.arn
}

output "url" {
  description = "Issuer URL of the provider"
  value       = aws_iam_openid_connect_provider.provider.url
}

output "provider_host" {
  description = "Issuer URL without the scheme. The prefix of every condition key in a trust policy, for example token.actions.githubusercontent.com:sub."
  value       = local.provider_host
}

output "assume_role_policy" {
  description = "Trust policy JSON restricting sts:AssumeRoleWithWebIdentity to var.subjects and var.client_id_list. Feed straight into the iam/role module's assume_role_policy."
  value       = local.assume_role_policy
}

output "subject_condition_operator" {
  description = "Condition operator chosen for the subject claim, StringLike when any subject holds a wildcard and StringEquals otherwise. Input-derived, so it is known at plan time."
  value       = local.subject_operator
}
