resource "aws_iam_policy" "policy" {
  name        = var.policy_name
  description = var.description
  path        = var.path
  policy      = var.policy_document
  tags        = var.tags
}
