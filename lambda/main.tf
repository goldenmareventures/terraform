locals {
  lambda_zip_path = "${var.lambda_path}/dist/index.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = "${path.root}/${local.lambda_zip_path}"
  function_name    = var.lambda_name
  role             = var.lambda_role_arn
  handler          = var.handler
  runtime          = var.runtime
  source_code_hash = filebase64sha256("${path.root}/${local.lambda_zip_path}")
  timeout          = var.timeout
  layers           = var.layers
  memory_size      = var.memory_size

  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Only valid when environment variables exist.
  kms_key_arn = length(var.env_vars) > 0 ? var.kms_key_arn : null

  dynamic "environment" {
    for_each = length(var.env_vars) > 0 ? [1] : []
    content {
      variables = var.env_vars
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_mode != null ? [1] : []
    content {
      mode = var.tracing_mode
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  tags = merge(
    {
      Environment : var.environment
    },
    var.tags
  )
}
