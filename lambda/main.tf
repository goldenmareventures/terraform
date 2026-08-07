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

  dynamic "environment" {
    for_each = length(var.env_vars) > 0 ? [1] : []
    content {
      variables = var.env_vars
    }
  }

  tags = merge(
    {
      Environment : var.environment
    },
    var.tags
  )
}
