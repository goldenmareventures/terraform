resource "aws_elasticache_cluster" "memcached" {
  count = local.is_memcached ? 1 : 0

  cluster_id      = var.name
  engine          = "memcached"
  engine_version  = var.engine_version
  node_type       = var.node_type
  port            = local.port
  num_cache_nodes = var.num_cache_nodes

  # AWS rejects cross-az on a single node. Spreading more than one node over
  # zones is the safe default, so the mode follows the node count.
  az_mode                      = var.num_cache_nodes > 1 ? "cross-az" : "single-az"
  preferred_availability_zones = length(var.availability_zones) == 0 ? null : var.availability_zones

  subnet_group_name    = local.subnet_group_name
  security_group_ids   = var.security_group_ids
  parameter_group_name = local.parameter_group_name

  transit_encryption_enabled = var.transit_encryption_enabled

  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  notification_topic_arn     = var.notification_topic_arn

  tags = var.tags
}
