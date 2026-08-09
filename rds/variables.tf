variable "identifier" {
  description = "Identifier for the DB instance"
  type        = string
}

variable "engine" {
  description = "Database engine (mysql, mariadb, or postgres)"
  type        = string

  validation {
    condition     = contains(["mysql", "mariadb", "postgres"], var.engine)
    error_message = "engine must be mysql, mariadb, or postgres."
  }
}

variable "engine_version" {
  description = "Engine version (e.g. 8.0.35 or 16.3). A major-only value such as 16 tracks the latest minor."
  type        = string
}

variable "instance_class" {
  description = "Instance class for the primary and the default for replicas"
  type        = string
  default     = "db.t4g.micro"
}

variable "database_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = null
}

variable "port" {
  description = "Port for the instance. Defaults to 3306 for MySQL and MariaDB, 5432 for Postgres."
  type        = number
  default     = null
}

# Credentials
variable "username" {
  description = "Master username"
  type        = string
}

variable "manage_master_user_password" {
  description = "Let RDS manage the master password in Secrets Manager"
  type        = bool
  default     = true
}

variable "password" {
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

# Storage
variable "allocated_storage" {
  description = "Storage in GiB. Ignored when the instance is restored from a snapshot."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper limit in GiB for storage autoscaling. 0 disables autoscaling."
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1, io2, or standard)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "standard"], var.storage_type)
    error_message = "storage_type must be gp2, gp3, io1, io2, or standard."
  }
}

variable "iops" {
  description = "Provisioned IOPS. Required for io1 and io2. Only settable on gp3 above 400 GiB."
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput in MiBps. gp3 only, and only above 400 GiB."
  type        = number
  default     = null
}

variable "storage_encrypted" {
  description = "Encrypt instance storage"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ARN for storage encryption"
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
  description = "Security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "publicly_accessible" {
  description = "Give the instance a public address"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Run a synchronous standby in a second availability zone"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone for a single-AZ instance. Ignored when multi_az is true."
  type        = string
  default     = null
}

# Read replicas
variable "read_replicas" {
  description = "Map of same-region read replicas, keyed by replica identifier"
  type = map(object({
    instance_class          = optional(string)
    multi_az                = optional(bool, false)
    availability_zone       = optional(string)
    publicly_accessible     = optional(bool, false)
    backup_retention_period = optional(number, 0)
  }))
  default = {}
}

# Parameter and option groups
variable "parameter_group_family" {
  description = "Parameter group family (e.g. mysql8.0, postgres16). Required when parameters is set."
  type        = string
  default     = null
}

variable "parameters" {
  description = "DB parameters. Creates a parameter group when non-empty."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

variable "parameter_group_name" {
  description = "Existing parameter group to use instead of creating one"
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "Existing option group to attach. The module does not create option groups."
  type        = string
  default     = null
}

# Backup and maintenance
variable "backup_retention_period" {
  description = "Backup retention in days (0-35). 0 disables backups."
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily backup window in UTC (e.g. 07:00-09:00)"
  type        = string
  default     = null
}

variable "maintenance_window" {
  description = "Weekly maintenance window in UTC (e.g. sun:05:00-sun:06:00)"
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Copy instance tags to snapshots"
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Delete automated backups when the instance is destroyed"
  type        = bool
  default     = true
}

variable "snapshot_identifier" {
  description = "Snapshot to restore the instance from"
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

# Auth and protection
variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

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
  description = "Logs to export. MySQL and MariaDB: audit, error, general, slowquery. Postgres: postgresql, upgrade."
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights. Not supported on micro and small instance classes."
  type        = bool
  default     = false
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
