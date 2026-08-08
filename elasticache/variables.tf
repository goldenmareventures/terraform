variable "name" {
  description = "Replication group ID for Redis and Valkey, or cluster ID for Memcached"
  type        = string
}

variable "description" {
  description = "Description for the replication group. Ignored for Memcached."
  type        = string
  default     = null
}

variable "engine" {
  description = "Cache engine (redis, valkey, or memcached)"
  type        = string
  default     = "valkey"

  validation {
    condition     = contains(["redis", "valkey", "memcached"], var.engine)
    error_message = "engine must be redis, valkey, or memcached."
  }
}

variable "engine_version" {
  description = "Engine version (e.g. 7.1 for Redis, 8.0 for Valkey, 1.6.22 for Memcached)"
  type        = string
}

variable "node_type" {
  description = "Node type for every node in the cache"
  type        = string
  default     = "cache.t4g.micro"
}

variable "port" {
  description = "Port for the cache. Defaults to 6379 for Redis and Valkey, 11211 for Memcached."
  type        = number
  default     = null
}

# Sizing
variable "num_cache_clusters" {
  description = "Primary plus replicas for Redis and Valkey with cluster mode off. Above 1 turns on automatic failover."
  type        = number
  default     = 1
}

variable "cluster_mode_enabled" {
  description = "Shard the keyspace over node groups. Redis and Valkey only."
  type        = bool
  default     = false
}

variable "num_node_groups" {
  description = "Number of shards. Only used when cluster_mode_enabled is true."
  type        = number
  default     = 2
}

variable "replicas_per_node_group" {
  description = "Replicas in each shard (0-5). Only used when cluster_mode_enabled is true."
  type        = number
  default     = 1
}

variable "num_cache_nodes" {
  description = "Number of nodes. Memcached only."
  type        = number
  default     = 1
}

variable "multi_az_enabled" {
  description = "Place replicas in other zones and fail over across zones. Redis and Valkey only."
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "Zones for the nodes. The length must match the node count. Ignored when cluster_mode_enabled is true."
  type        = list(string)
  default     = []
}

# Networking
variable "create_subnet_group" {
  description = "Create a cache subnet group from subnet_ids"
  type        = bool
  default     = true
}

variable "subnet_group_name" {
  description = "Existing subnet group name, or the name to give a created one"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the created subnet group"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the cache"
  type        = list(string)
  default     = []
}

# Encryption and auth
variable "at_rest_encryption_enabled" {
  description = "Encrypt data at rest. Redis and Valkey only."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for encryption at rest. AWS uses its own key when null."
  type        = string
  default     = null
}

variable "transit_encryption_enabled" {
  description = "Encrypt data in transit. Clients must connect over TLS when this is true. Memcached needs engine 1.6.12 or later."
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "AUTH password (16-128 characters). Requires transit_encryption_enabled. Redis and Valkey only."
  type        = string
  default     = null
  sensitive   = true
}

variable "user_group_ids" {
  description = "RBAC user group IDs. An alternative to auth_token on Redis 6 and later."
  type        = list(string)
  default     = null
}

# Parameters
variable "parameter_group_family" {
  description = "Parameter group family (e.g. redis7, valkey8, memcached1.6). Required when parameters is set."
  type        = string
  default     = null
}

variable "parameters" {
  description = "Cache parameters. Creates a parameter group when non-empty."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "parameter_group_name" {
  description = "Existing parameter group to use instead of creating one"
  type        = string
  default     = null
}

# Snapshots and maintenance
variable "snapshot_retention_limit" {
  description = "Days to keep automatic snapshots (0-35). 0 disables them. Redis and Valkey only."
  type        = number
  default     = 0
}

variable "snapshot_window" {
  description = "Daily snapshot window in UTC (e.g. 03:00-05:00)"
  type        = string
  default     = null
}

variable "snapshot_arns" {
  description = "S3 ARNs of RDB files to seed the cache from on creation"
  type        = list(string)
  default     = null
}

variable "final_snapshot_identifier" {
  description = "Name for a snapshot taken on destroy. No snapshot is taken when null."
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC (e.g. sun:05:00-sun:06:00)"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor engine version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window"
  type        = bool
  default     = false
}

# Observability
variable "notification_topic_arn" {
  description = "SNS topic ARN for ElastiCache events"
  type        = string
  default     = null
}

variable "log_delivery_configurations" {
  description = "Log streams to deliver. Redis and Valkey 6.2 and later only."
  type = list(object({
    destination      = string
    destination_type = string
    log_format       = optional(string, "json")
    log_type         = string
  }))
  default = []

  validation {
    condition     = alltrue([for c in var.log_delivery_configurations : contains(["cloudwatch-logs", "kinesis-firehose"], c.destination_type)])
    error_message = "destination_type must be cloudwatch-logs or kinesis-firehose."
  }

  validation {
    condition     = alltrue([for c in var.log_delivery_configurations : contains(["slow-log", "engine-log"], c.log_type)])
    error_message = "log_type must be slow-log or engine-log."
  }

  validation {
    condition     = alltrue([for c in var.log_delivery_configurations : contains(["json", "text"], c.log_format)])
    error_message = "log_format must be json or text."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
