resource "aws_ssm_parameter" "ssm_variables" {
  for_each = var.ssm_variables

  name        = each.value.name
  description = each.value.description
  type        = each.value.type
  value       = each.value.value

  tags = var.tags
}
