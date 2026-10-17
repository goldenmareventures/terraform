resource "aws_secretsmanager_secret" "secret" {
  for_each = var.secrets

  name                    = each.value.name
  description             = each.value.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

# External secrets get no version, so Terraform never owns or overwrites a value a human sets.
resource "aws_secretsmanager_secret_version" "generated" {
  for_each = { for k, v in var.secrets : k => v if !v.external }

  secret_id     = aws_secretsmanager_secret.secret[each.key].id
  secret_string = var.secret_values[each.key]
}

resource "aws_secretsmanager_secret_policy" "policy" {
  for_each = { for k, v in var.secrets : k => v if v.policy != null }

  secret_arn          = aws_secretsmanager_secret.secret[each.key].arn
  policy              = each.value.policy
  block_public_policy = true
}
