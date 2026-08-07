variable "cluster_identifier" {
  description = "Identifier for the Aurora cluster"
  type        = string
}

variable "engine" {
  description = "Aurora engine (aurora-mysql or aurora-postgresql)"
  type        = string

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.engine)
    error_message = "engine must be aurora-mysql or aurora-postgresql."
  }
}

variable "engine_version" {
  description = "Engine version (e.g. 8.0.mysql_aurora.3.05.2 or 15.4)"
  type        = string
}

variable "database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = null
}

variable "port" {
  description = "Port for the cluster. Defaults to 3306 for MySQL and 5432 for Postgres."
  type        = number
  default     = null
}

# Credentials
variable "master_username" {
  description = "Master username"
  type        = string
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password in Secrets Manager"
  type        = bool
  default     = true
}

variable "master_password" {
  description = "Master password. Only used when manage_master_user_password is false."
  type        = string
  default     = null
  sensitive   = true
}

variable "master_user_secret_kms_key_id" {
  description = "KMS key for the managed master user secret"
  type        = string
  default     = null
}

# Networking
variable "create_subnet_group" {
  description = "Create a DB subnet group from subnet_ids"
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

variable "vpc_security_group_ids" {
  description = "Security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "availability_zones" {
  description = "Availability zones for the cluster"
  type        = list(string)
  default     = null
}

variable "publicly_accessible" {
  description = "Make instances publicly accessible"
  type        = bool
  default     = false
}

# Instances
variable "instances" {
  description = "Map of cluster instances, keyed by instance identifier"
  type = map(object({
    instance_class    = optional(string)
    promotion_tier    = optional(number, 1)
    availability_zone = optional(string)
  }))
  default = {}
}

variable "instance_class" {
  description = "Default instance class. Ignored when serverlessv2_scaling is set."
  type        = string
  default     = "db.t4g.medium"
}

variable "serverlessv2_scaling" {
  description = "Serverless v2 scaling. When set, all instances use db.serverless."
  type = object({
    min_capacity             = number
    max_capacity             = number
    seconds_until_auto_pause = optional(number)
  })
  default = null
}

# Parameter groups
variable "cluster_parameter_group_family" {
  description = "Cluster parameter group family (e.g. aurora-mysql8.0, aurora-postgresql15)"
  type        = string
  default     = null
}

variable "cluster_parameters" {
  description = "Cluster-level parameters. Creates a cluster parameter group when non-empty."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "cluster_parameter_group_name" {
  description = "Existing cluster parameter group to use instead of creating one"
  type        = string
  default     = null
}

variable "instance_parameter_group_family" {
  description = "Instance parameter group family. Required when instance_parameters is set."
  type        = string
  default     = null
}

variable "instance_parameters" {
  description = "Instance-level parameters. Creates a DB parameter group when non-empty."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "instance_parameter_group_name" {
  description = "Existing instance parameter group to use instead of creating one"
  type        = string
  default     = null
}

# Backup and maintenance
variable "backup_retention_period" {
  description = "Backup retention in days (1-35)"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily backup window in UTC (e.g. 07:00-09:00)"
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "Weekly maintenance window in UTC (e.g. sun:05:00-sun:06:00)"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy cluster tags to snapshots"
  type        = bool
  default     = true
}

variable "backtrack_window" {
  description = "Backtrack window in seconds. Aurora MySQL only. 0 disables."
  type        = number
  default     = 0
}

variable "snapshot_identifier" {
  description = "Snapshot to restore the cluster from"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Name for the final snapshot"
  type        = string
  default     = null
}

# Encryption and auth
variable "storage_encrypted" {
  description = "Encrypt cluster storage"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption"
  type        = string
  default     = null
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

# Protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during the maintenance window"
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Allow major engine version upgrades"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "ca_cert_identifier" {
  description = "CA certificate identifier (e.g. rds-ca-rsa2048-g1)"
  type        = string
  default     = null
}

# Observability
variable "enabled_cloudwatch_logs_exports" {
  description = "Logs to export. MySQL: audit, error, general, slowquery. Postgres: postgresql."
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention in days (7, 731, or a multiple of 31)"
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "KMS key for Performance Insights data"
  type        = string
  default     = null
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60). 0 disables."
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "Existing Enhanced Monitoring role. A role is created when this is null and monitoring_interval is above 0."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
