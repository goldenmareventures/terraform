locals {
  redis     = one(aws_elasticache_replication_group.redis)
  memcached = one(aws_elasticache_cluster.memcached)
}

output "id" {
  description = "Replication group ID for Redis and Valkey, or cluster ID for Memcached"
  value       = try(local.redis.id, local.memcached.cluster_id)
}

output "arn" {
  description = "ARN of the replication group or cluster"
  value       = try(local.redis.arn, local.memcached.arn)
}

output "engine" {
  description = "Engine in use"
  value       = var.engine
}

output "port" {
  description = "Port the cache listens on"
  value       = local.port
}

output "primary_endpoint_address" {
  description = "Write endpoint. Redis and Valkey with cluster mode off only."
  value       = try(local.redis.primary_endpoint_address, null)
}

output "reader_endpoint_address" {
  description = "Read endpoint across the replicas. Redis and Valkey with cluster mode off only."
  value       = try(local.redis.reader_endpoint_address, null)
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint. Redis and Valkey with cluster mode on, or Memcached."
  value       = try(local.redis.configuration_endpoint_address, local.memcached.configuration_endpoint, null)
}

output "member_clusters" {
  description = "Cluster IDs in the replication group"
  value       = try(local.redis.member_clusters, [])
}

output "cache_nodes" {
  description = "Memcached nodes with address, port, and zone"
  value       = try(local.memcached.cache_nodes, [])
}

output "subnet_group_name" {
  description = "Name of the subnet group in use"
  value       = local.subnet_group_name
}

output "parameter_group_name" {
  description = "Name of the parameter group in use"
  value       = local.parameter_group_name
}
