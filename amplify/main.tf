resource "aws_amplify_app" "app" {
  name                 = var.app_name
  repository           = var.repository_url
  iam_service_role_arn = var.service_role_arn
  compute_role_arn     = var.compute_role_arn
  platform             = var.platform
  oauth_token          = var.oauth_token
  access_token         = var.access_token

  environment_variables = merge(
    var.default_environment_variables,
    var.custom_environment_variables
  )

  dynamic "custom_rule" {
    for_each = var.custom_rules
    content {
      source = custom_rule.value.source
      status = custom_rule.value.status
      target = custom_rule.value.target
    }
  }

  lifecycle {
    ignore_changes = [oauth_token]
  }

  tags = var.tags
}

resource "aws_amplify_branch" "branches" {
  for_each = var.branches

  app_id       = aws_amplify_app.app.id
  branch_name  = each.key
  display_name = lookup(each.value, "display_name", each.key)

  framework         = lookup(each.value, "framework", var.default_framework)
  stage             = lookup(each.value, "stage", "DEVELOPMENT")
  enable_auto_build = lookup(each.value, "enable_auto_build", true)

  environment_variables = lookup(each.value, "environment_variables", {})

  tags = var.tags
}

resource "aws_amplify_domain_association" "domain" {
  count = var.domain_name != null ? 1 : 0

  app_id                 = aws_amplify_app.app.id
  domain_name            = var.domain_name
  enable_auto_sub_domain = var.enable_auto_sub_domain
  wait_for_verification  = var.wait_for_verification

  dynamic "sub_domain" {
    for_each = var.sub_domains
    content {
      branch_name = aws_amplify_branch.branches[sub_domain.value.branch_name].branch_name
      prefix      = sub_domain.value.prefix
    }
  }
}
