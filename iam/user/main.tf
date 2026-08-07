# modules/iam/user/main.tf
resource "aws_iam_user" "user" {
  name = var.user_name
  path = var.path

  tags = var.tags
}

resource "aws_iam_access_key" "user_key" {
  count = var.create_access_key ? 1 : 0

  user = aws_iam_user.user.name
}

resource "aws_iam_user_policy_attachment" "managed_policies" {
  for_each = toset(var.managed_policy_arns)

  user       = aws_iam_user.user.name
  policy_arn = each.value
}

resource "aws_iam_user_policy" "inline_policies" {
  for_each = var.inline_policies

  name   = each.key
  user   = aws_iam_user.user.name
  policy = each.value
}
