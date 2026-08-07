# vpc/flow_logs.tf
locals {
  flow_log_enabled = var.flow_log != null

  # CloudWatch delivery needs a log group and a role. S3 delivery needs neither.
  flow_log_to_cloudwatch = local.flow_log_enabled && try(var.flow_log.destination_type, "") == "cloud-watch-logs"
}

resource "aws_cloudwatch_log_group" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  name              = "/aws/vpc/${var.name}"
  retention_in_days = var.flow_log.retention_in_days
  kms_key_id        = var.flow_log.kms_key_arn

  tags = var.tags
}

data "aws_iam_policy_document" "flow_log_assume" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_log[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  name               = "${var.name}-vpc-flow-log"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = local.flow_log_to_cloudwatch ? 1 : 0

  name   = "${var.name}-vpc-flow-log"
  role   = aws_iam_role.flow_log[0].id
  policy = data.aws_iam_policy_document.flow_log[0].json
}

resource "aws_flow_log" "flow_log" {
  count = local.flow_log_enabled ? 1 : 0

  vpc_id       = aws_vpc.vpc.id
  traffic_type = var.flow_log.traffic_type

  log_destination_type = var.flow_log.destination_type
  log_destination      = local.flow_log_to_cloudwatch ? aws_cloudwatch_log_group.flow_log[0].arn : var.flow_log.s3_bucket_arn
  iam_role_arn         = local.flow_log_to_cloudwatch ? aws_iam_role.flow_log[0].arn : null

  max_aggregation_interval = var.flow_log.max_aggregation_interval

  tags = merge(var.tags, { Name = var.name })
}
