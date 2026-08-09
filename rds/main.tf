locals {
  is_postgres = var.engine == "postgres"

  default_port = local.is_postgres ? 5432 : 3306

  subnet_group_name = var.create_subnet_group ? aws_db_subnet_group.subnet_group[0].name : var.subnet_group_name

  parameter_group_name = local.create_parameter_group ? aws_db_parameter_group.instance[0].name : var.parameter_group_name

  create_monitoring_role = var.monitoring_interval > 0 && var.monitoring_role_arn == null

  monitoring_role_arn = local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : var.monitoring_role_arn
}

resource "aws_db_subnet_group" "subnet_group" {
  count = var.create_subnet_group ? 1 : 0

  name        = coalesce(var.subnet_group_name, "${var.identifier}-subnet-group")
  description = "Subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

resource "aws_db_instance" "instance" {
  identifier     = var.identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name = var.database_name
  port    = coalesce(var.port, local.default_port)

  username                      = var.username
  password                      = var.manage_master_user_password ? null : var.password
  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.iops
  storage_throughput    = var.storage_throughput
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_subnet_group_name   = local.subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  # A Multi-AZ instance picks its own zones. Sending both is an API error.
  availability_zone = var.multi_az ? null : var.availability_zone

  parameter_group_name = local.parameter_group_name
  option_group_name    = var.option_group_name

  backup_retention_period  = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  copy_tags_to_snapshot    = var.copy_tags_to_snapshot
  delete_automated_backups = var.delete_automated_backups

  snapshot_identifier       = var.snapshot_identifier
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.identifier}-final")

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.monitoring_role_arn

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  deletion_protection         = var.deletion_protection
  apply_immediately           = var.apply_immediately
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  ca_cert_identifier          = var.ca_cert_identifier

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # A restored instance keeps this set. Without the ignore, every later
      # plan wants to destroy and rebuild the instance.
      snapshot_identifier,
    ]
  }
}
