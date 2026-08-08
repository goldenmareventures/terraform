locals {
  is_memcached = var.engine == "memcached"

  port = coalesce(var.port, local.is_memcached ? 11211 : 6379)

  subnet_group_name = var.create_subnet_group ? aws_elasticache_subnet_group.subnet_group[0].name : var.subnet_group_name

  parameter_group_name = local.create_parameter_group ? aws_elasticache_parameter_group.cache[0].name : var.parameter_group_name

  # Cluster mode and Multi-AZ both require automatic failover, and failover
  # requires more than one node. Deriving the flag removes a combination the
  # API rejects, so there is no separate variable for it.
  automatic_failover_enabled = var.cluster_mode_enabled || var.multi_az_enabled || var.num_cache_clusters > 1
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  count = var.create_subnet_group ? 1 : 0

  name        = coalesce(var.subnet_group_name, "${var.name}-subnet-group")
  description = "Subnet group for ${var.name}"
  subnet_ids  = var.subnet_ids

  tags = var.tags
}
