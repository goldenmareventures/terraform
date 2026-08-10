# modules/oidc/main.tf
locals {
  # A trust policy condition keys off the provider HOST, not the full URL:
  # "token.actions.githubusercontent.com:sub", never "https://token.../:sub".
  # Getting this wrong produces a policy that parses and never matches.
  provider_host = replace(var.url, "https://", "")

  # A wildcard subject silently never matches under StringEquals. Pick the
  # operator from the subjects themselves so the caller cannot get this pair
  # wrong.
  subject_operator = length([
    for s in var.subjects : s if length(regexall("\\*", s)) > 0
  ]) > 0 ? "StringLike" : "StringEquals"

  audience_condition = { "${local.provider_host}:aud" = var.client_id_list }

  subject_condition = length(var.subjects) == 0 ? {} : {
    "${local.provider_host}:sub" = var.subjects
  }

  # The audience is always StringEquals. When the subject is too, both claims
  # have to go in ONE StringEquals block: a top-level merge would overwrite the
  # audience with the subject and silently drop the aud check.
  condition = local.subject_operator == "StringEquals" ? {
    StringEquals = merge(local.audience_condition, local.subject_condition)
    } : {
    StringEquals = local.audience_condition
    StringLike   = local.subject_condition
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"

      Principal = {
        Federated = aws_iam_openid_connect_provider.provider.arn
      }

      Condition = local.condition
    }]
  })
}

resource "aws_iam_openid_connect_provider" "provider" {
  url = var.url

  client_id_list = var.client_id_list

  # Optional. AWS validates well-known providers such as
  # token.actions.githubusercontent.com against its own trust store and ignores
  # a supplied thumbprint, so leaving this empty is correct for GitHub.
  thumbprint_list = var.thumbprint_list

  tags = var.tags
}
