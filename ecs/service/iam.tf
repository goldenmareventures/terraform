# modules/ecs/service/iam.tf
locals {
  create_execution_role = var.execution_role_arn == null
  create_task_role      = var.task_role_arn == null

  execution_role_arn = local.create_execution_role ? aws_iam_role.execution[0].arn : var.execution_role_arn
  task_role_arn      = local.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Execution role. ECS itself uses it to pull the image, read the secrets, and
# write the logs. It is not the role the application code sees.
resource "aws_iam_role" "execution" {
  count = local.create_execution_role ? 1 : 0

  name               = "${var.name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(var.tags, { Name = "${var.name}-ecs-execution" })
}

resource "aws_iam_role_policy_attachment" "execution_default" {
  count = local.create_execution_role ? 1 : 0

  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "execution_extra" {
  for_each = local.create_execution_role ? toset(var.execution_role_policy_arns) : toset([])

  role       = aws_iam_role.execution[0].name
  policy_arn = each.value
}

data "aws_iam_policy_document" "execution_secrets" {
  count = local.create_execution_role && length(var.execution_role_secret_arns) > 0 ? 1 : 0

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "ssm:GetParameters",
      "kms:Decrypt",
    ]
    resources = var.execution_role_secret_arns
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = local.create_execution_role && length(var.execution_role_secret_arns) > 0 ? 1 : 0

  name   = "${var.name}-ecs-secrets"
  role   = aws_iam_role.execution[0].id
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

# Task role. The application code inside the container assumes this one.
resource "aws_iam_role" "task" {
  count = local.create_task_role ? 1 : 0

  name               = "${var.name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = merge(var.tags, { Name = "${var.name}-ecs-task" })
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = local.create_task_role ? toset(var.task_role_policy_arns) : toset([])

  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task_inline" {
  for_each = local.create_task_role ? var.task_role_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.task[0].id
  policy = each.value
}

# ECS Exec opens an SSM channel from inside the container, so the permission
# belongs to the task role and not to the execution role.
data "aws_iam_policy_document" "execute_command" {
  count = local.create_task_role && var.enable_execute_command ? 1 : 0

  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "execute_command" {
  count = local.create_task_role && var.enable_execute_command ? 1 : 0

  name   = "${var.name}-ecs-exec"
  role   = aws_iam_role.task[0].id
  policy = data.aws_iam_policy_document.execute_command[0].json
}
