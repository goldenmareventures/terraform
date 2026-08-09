locals {
  # Create a group only when we have parameters AND the caller did not
  # point at an existing group.
  create_parameter_group = length(var.parameters) > 0 && var.parameter_group_name == null
}

resource "aws_db_parameter_group" "instance" {
  count = local.create_parameter_group ? 1 : 0

  name        = "${var.identifier}-params"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = var.parameter_group_family != null
      error_message = "parameter_group_family is required when parameters is set."
    }
  }

  tags = var.tags
}
