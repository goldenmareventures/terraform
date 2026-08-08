resource "aws_elasticache_replication_group" "redis" {
  count = local.is_memcached ? 0 : 1

  replication_group_id = var.name
  description          = coalesce(var.description, "Cache for ${var.name}")

  engine         = var.engine
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = local.port

  # Cluster mode on shards the keyspace over node groups. Cluster mode off is
  # one group of a primary plus replicas. The API rejects both sets together.
  num_cache_clusters      = var.cluster_mode_enabled ? null : var.num_cache_clusters
  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group = var.cluster_mode_enabled ? var.replicas_per_node_group : null

  automatic_failover_enabled = local.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # AWS places the nodes for a cluster mode group itself and rejects a zone
  # list. The list length must match num_cache_clusters when it is sent.
  preferred_cache_cluster_azs = var.cluster_mode_enabled || length(var.availability_zones) == 0 ? null : var.availability_zones

  subnet_group_name    = local.subnet_group_name
  security_group_ids   = var.security_group_ids
  parameter_group_name = local.parameter_group_name

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.at_rest_encryption_enabled ? var.kms_key_id : null
  transit_encryption_enabled = var.transit_encryption_enabled

  # AWS only accepts an auth token when transit encryption is on. RBAC user
  # groups are the alternative and the two cannot both be set.
  auth_token                 = var.transit_encryption_enabled ? var.auth_token : null
  auth_token_update_strategy = var.transit_encryption_enabled && var.auth_token != null ? "ROTATE" : null
  user_group_ids             = var.user_group_ids

  snapshot_retention_limit  = var.snapshot_retention_limit
  snapshot_window           = var.snapshot_window
  snapshot_arns             = var.snapshot_arns
  final_snapshot_identifier = var.final_snapshot_identifier

  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  notification_topic_arn     = var.notification_topic_arn

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery_configurations
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !var.multi_az_enabled || var.cluster_mode_enabled || var.num_cache_clusters > 1
      error_message = "multi_az_enabled requires num_cache_clusters above 1 when cluster_mode_enabled is false."
    }
    precondition {
      condition     = var.auth_token == null || var.transit_encryption_enabled
      error_message = "auth_token requires transit_encryption_enabled to be true."
    }
    ignore_changes = [
      # A group restored from a snapshot keeps these set. Without the ignore,
      # every later plan wants to destroy and rebuild the group.
      snapshot_arns,
    ]
  }
}
