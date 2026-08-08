# modules/elasticache/README.md
# ElastiCache Module

Terraform module for an Amazon ElastiCache cache. The module supports Valkey, Redis, and
Memcached from one interface, and picks the right AWS resource from `engine`.

Valkey and Redis create an `aws_elasticache_replication_group`. Memcached creates an
`aws_elasticache_cluster`.

## Features

- Valkey, Redis, and Memcached from one module
- Cluster mode on or off, with shards and replicas
- Multi-AZ with automatic failover
- Encryption at rest and in transit
- AUTH token or RBAC user groups
- Automatic snapshots, and restore from RDB files in S3
- Subnet group created on demand
- Parameter group created on demand
- Slow-log and engine-log delivery to CloudWatch Logs or Firehose

## Usage

### Single Valkey node, development

```terraform
module "cache" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//elasticache?ref=v1.13.0"

  name           = "app-dev"
  engine         = "valkey"
  engine_version = "8.0"
  node_type      = "cache.t4g.micro"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.cache.id]

  tags = local.tags
}
```

### Valkey with a replica and Multi-AZ

```terraform
module "cache" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//elasticache?ref=v1.13.0"

  name           = "app-prod"
  engine         = "valkey"
  engine_version = "8.0"
  node_type      = "cache.m7g.large"

  num_cache_clusters = 2
  multi_az_enabled   = true

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.cache.id]

  transit_encryption_enabled = true
  snapshot_retention_limit   = 7
  snapshot_window            = "03:00-05:00"
  maintenance_window         = "sun:05:00-sun:06:00"

  tags = local.tags
}
```

### Redis with cluster mode on

```terraform
module "sessions" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//elasticache?ref=v1.13.0"

  name           = "sessions-prod"
  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.m7g.large"

  cluster_mode_enabled    = true
  num_node_groups         = 3
  replicas_per_node_group = 1

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.cache.id]

  transit_encryption_enabled = true
  auth_token                 = var.cache_auth_token

  tags = local.tags
}
```

### Memcached

```terraform
module "page_cache" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//elasticache?ref=v1.13.0"

  name           = "pages-prod"
  engine         = "memcached"
  engine_version = "1.6.22"
  node_type      = "cache.t4g.small"

  num_cache_nodes = 2

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.cache.id]

  tags = local.tags
}
```

### Custom parameters and log delivery

Pass the family when you pass parameters. The module does not guess the family from the
engine version.

```terraform
module "cache" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//elasticache?ref=v1.13.0"

  name           = "app-prod"
  engine         = "valkey"
  engine_version = "8.0"

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.cache.id]

  parameter_group_family = "valkey8"
  parameters = [
    { name = "maxmemory-policy", value = "allkeys-lru" },
    { name = "timeout", value = "300" }
  ]

  log_delivery_configurations = [
    {
      destination      = aws_cloudwatch_log_group.cache_slow.name
      destination_type = "cloudwatch-logs"
      log_type         = "slow-log"
    },
    {
      destination      = aws_cloudwatch_log_group.cache_engine.name
      destination_type = "cloudwatch-logs"
      log_type         = "engine-log"
    }
  ]

  tags = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Replication group ID or cluster ID | string | - | yes |
| engine_version | Engine version | string | - | yes |
| engine | redis, valkey, or memcached | string | valkey | no |
| description | Replication group description | string | null | no |
| node_type | Node type | string | cache.t4g.micro | no |
| port | Cache port | number | 6379 or 11211 | no |
| num_cache_clusters | Primary plus replicas, cluster mode off | number | 1 | no |
| cluster_mode_enabled | Shard the keyspace | bool | false | no |
| num_node_groups | Shards, cluster mode on | number | 2 | no |
| replicas_per_node_group | Replicas in each shard | number | 1 | no |
| num_cache_nodes | Nodes, Memcached only | number | 1 | no |
| multi_az_enabled | Fail over across zones | bool | false | no |
| availability_zones | Zones for the nodes | list(string) | [] | no |
| create_subnet_group | Create a subnet group | bool | true | no |
| subnet_group_name | Subnet group name | string | null | no |
| subnet_ids | Subnets for the created subnet group | list(string) | [] | no |
| security_group_ids | Security groups for the cache | list(string) | [] | no |
| at_rest_encryption_enabled | Encrypt data at rest | bool | true | no |
| kms_key_id | KMS key for encryption at rest | string | null | no |
| transit_encryption_enabled | Encrypt data in transit | bool | false | no |
| auth_token | AUTH password | string | null | no |
| user_group_ids | RBAC user group IDs | list(string) | null | no |
| parameter_group_family | Parameter group family | string | null | no |
| parameters | Cache parameters | list(object) | [] | no |
| parameter_group_name | Existing parameter group | string | null | no |
| snapshot_retention_limit | Snapshot retention in days | number | 0 | no |
| snapshot_window | Snapshot window in UTC | string | null | no |
| snapshot_arns | S3 RDB files to seed from | list(string) | null | no |
| final_snapshot_identifier | Snapshot name on destroy | string | null | no |
| maintenance_window | Maintenance window in UTC | string | null | no |
| auto_minor_version_upgrade | Allow minor upgrades | bool | true | no |
| apply_immediately | Apply changes immediately | bool | false | no |
| notification_topic_arn | SNS topic for cache events | string | null | no |
| log_delivery_configurations | Log streams to deliver | list(object) | [] | no |
| tags | Tags to apply | map(string) | {} | no |

### Log delivery object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| destination | Log group name or Firehose stream name | string | - |
| destination_type | cloudwatch-logs or kinesis-firehose | string | - |
| log_type | slow-log or engine-log | string | - |
| log_format | json or text | string | json |

## Outputs

| Name | Description |
|------|-------------|
| id | Replication group ID or cluster ID |
| arn | ARN of the replication group or cluster |
| engine | Engine in use |
| port | Port the cache listens on |
| primary_endpoint_address | Write endpoint, cluster mode off |
| reader_endpoint_address | Read endpoint, cluster mode off |
| configuration_endpoint_address | Configuration endpoint, cluster mode on or Memcached |
| member_clusters | Cluster IDs in the replication group |
| cache_nodes | Memcached nodes with address, port, and zone |
| subnet_group_name | Subnet group in use |
| parameter_group_name | Parameter group in use |

## Notes

### Pick the endpoint that matches the mode

The endpoints are not interchangeable, and only one set is populated per cache.

- Cluster mode off: `primary_endpoint_address` for writes, `reader_endpoint_address` for reads.
- Cluster mode on: `configuration_endpoint_address`, with a cluster-aware client.
- Memcached: `configuration_endpoint_address` for auto discovery, or `cache_nodes` for the
  node list.

The unused outputs are `null` or an empty list, so a consumer can select on `engine`.

### Automatic failover is derived, not a variable

AWS requires automatic failover when cluster mode is on or Multi-AZ is on, and failover needs
more than one node. The module turns failover on when any of those is true. This removes a
combination the API rejects. There is no `automatic_failover_enabled` variable.

A `multi_az_enabled = true` with `num_cache_clusters = 1` still fails, so the module blocks it
with a precondition at plan time instead of at apply time.

### Single node by default

`num_cache_clusters` defaults to 1 and `num_cache_nodes` defaults to 1. A single node has no
failover and loses its data on a node replacement. Set `num_cache_clusters = 2` and
`multi_az_enabled = true` for production.

### Snapshots are off by default

`snapshot_retention_limit` defaults to 0, which matches the AWS default. A cache is usually not
a system of record. Turn snapshots on when the cache holds sessions or another value you cannot
rebuild. Memcached has no snapshots at all.

### Transit encryption and the AUTH token

`auth_token` needs `transit_encryption_enabled = true`. The module drops the token when transit
encryption is off, and a precondition reports the mistake at plan time.

Turning transit encryption on is a client change. Every client must connect over TLS. Changing
the flag on a live cache replaces or restarts nodes, so plan an outage window.

Use `user_group_ids` for RBAC on Redis 6 and later instead of a shared token. Do not set both.

### Engine versions and families

Valkey uses `8.0` and family `valkey8`. Redis uses `7.1` and family `redis7`. Memcached uses
`1.6.22` and family `memcached1.6`. The module does not derive the family from the version. The
group uses `create_before_destroy`, so a family change replaces the group without an ordering
failure.

The module ships no default parameters. Pass what you need.

### Log delivery is Redis and Valkey only

`log_delivery_configurations` is ignored for Memcached, which produces no engine or slow log.
Redis needs 6.2 or later for log delivery. Create the CloudWatch log group in the calling
project and pass its name.

### Ignored changes

The replication group ignores changes to `snapshot_arns`. A group seeded from S3 keeps the value
set, and without the ignore every later plan wants to rebuild the group.

### Serverless is a different resource

This module does not cover ElastiCache Serverless. `aws_elasticache_serverless_cache` has its
own sizing, scaling, and endpoint model and shares almost no arguments with these two resources.
Declare it in the calling project, or ask for a separate module.
