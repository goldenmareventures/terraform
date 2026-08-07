resource "aws_rds_cluster_parameter_group" "cluster" {
  count = local.create_cluster_parameter_group ? 1 : 0

  name        = "${var.cluster_identifier}-cluster-params"
  family      = var.cluster_parameter_group_family
  description = "Cluster parameter group for ${var.cluster_identifier}"

  dynamic "parameter" {
    for_each = local.merged_cluster_parameters
    content {
      name         = parameter.key
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
    precondition {
      condition     = var.cluster_parameter_group_family != null
      error_message = "cluster_parameter_group_family is required."
    }
  }

  tags = var.tags
}
