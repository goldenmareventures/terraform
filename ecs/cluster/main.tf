# modules/ecs/cluster/main.tf
resource "aws_ecs_cluster" "cluster" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  dynamic "configuration" {
    for_each = var.execute_command_configuration != null ? [var.execute_command_configuration] : []

    content {
      execute_command_configuration {
        kms_key_id = configuration.value.kms_key_id
        logging    = configuration.value.logging

        # log_configuration belongs to OVERRIDE only. AWS rejects it for
        # DEFAULT and for NONE.
        dynamic "log_configuration" {
          for_each = configuration.value.logging == "OVERRIDE" ? [1] : []

          content {
            cloud_watch_log_group_name     = configuration.value.cloud_watch_log_group_name
            cloud_watch_encryption_enabled = configuration.value.cloud_watch_encryption_enabled
            s3_bucket_name                 = configuration.value.s3_bucket_name
            s3_key_prefix                  = configuration.value.s3_key_prefix
            s3_bucket_encryption_enabled   = configuration.value.s3_bucket_encryption_enabled
          }
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_namespace != null ? [1] : []

    content {
      namespace = var.service_connect_namespace
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy

    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = default_capacity_provider_strategy.value.base
    }
  }
}
