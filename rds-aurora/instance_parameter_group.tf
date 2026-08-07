resource "aws_db_parameter_group" "instance" {
  count = local.create_instance_parameter_group ? 1 : 0

  name        = "${var.cluster_identifier}-instance-params"
  family      = var.instance_parameter_group_family
  description = "Instance parameter group for ${var.cluster_identifier}"

  dynamic "parameter" {
    for_each = local.merged_instance_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}
