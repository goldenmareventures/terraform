locals {
  is_mysql    = var.engine == "aurora-mysql"
  is_postgres = var.engine == "aurora-postgresql"

  # Serverless v2 instances use the reserved db.serverless class.
  serverless_enabled = var.serverlessv2_scaling != null

  create_monitoring_role = var.monitoring_interval > 0 && var.monitoring_role_arn == null

  monitoring_role_arn = local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : var.monitoring_role_arn
}

resource "aws_db_subnet_group" "subnet_group" {
  count = var.create_subnet_group ? 1 : 0

  name        = coalesce(var.subnet_group_name, "${var.cluster_identifier}-subnet-group")
  description = "Subnet group for ${var.cluster_identifier}"
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier = var.cluster_identifier
  engine             = var.engine
  engine_version     = var.engine_version
  engine_mode        = "provisioned"

  database_name = var.database_name
  port          = coalesce(var.port, local.is_mysql ? 3306 : 5432)

  master_username               = var.master_username
  master_password               = var.manage_master_user_password ? null : var.master_password
  manage_master_user_password   = var.manage_master_user_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_user_password ? var.master_user_secret_kms_key_id : null

  db_subnet_group_name   = var.create_subnet_group ? aws_db_subnet_group.subnet_group[0].name : var.subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  availability_zones     = var.availability_zones

  db_cluster_parameter_group_name = local.create_cluster_parameter_group ? aws_rds_cluster_parameter_group.cluster[0].name : var.cluster_parameter_group_name

  # Applies the instance parameter group to instances created by the cluster.
  db_instance_parameter_group_name = local.create_instance_parameter_group ? aws_db_parameter_group.instance[0].name : var.instance_parameter_group_name

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.cluster_identifier}-final")
  snapshot_identifier       = var.snapshot_identifier

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Backtrack is Aurora MySQL only. Sending it for Postgres is an API error.
  backtrack_window = local.is_mysql ? var.backtrack_window : null

  apply_immediately           = var.apply_immediately
  allow_major_version_upgrade = var.allow_major_version_upgrade

  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.serverless_enabled ? [var.serverlessv2_scaling] : []
    content {
      min_capacity             = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity             = serverlessv2_scaling_configuration.value.max_capacity
      seconds_until_auto_pause = serverlessv2_scaling_configuration.value.seconds_until_auto_pause
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # A restored cluster keeps this set. Without the ignore, every later
      # plan wants to destroy and rebuild the cluster.
      snapshot_identifier,
      availability_zones,
    ]
  }
}

resource "aws_rds_cluster_instance" "instances" {
  for_each = var.instances

  identifier         = each.key
  cluster_identifier = aws_rds_cluster.cluster.id

  # Engine and version must match the cluster.
  engine         = aws_rds_cluster.cluster.engine
  engine_version = aws_rds_cluster.cluster.engine_version

  instance_class = local.serverless_enabled ? "db.serverless" : coalesce(each.value.instance_class, var.instance_class)

  db_subnet_group_name    = aws_rds_cluster.cluster.db_subnet_group_name
  db_parameter_group_name = local.create_instance_parameter_group ? aws_db_parameter_group.instance[0].name : var.instance_parameter_group_name

  promotion_tier      = each.value.promotion_tier
  availability_zone   = each.value.availability_zone
  publicly_accessible = var.publicly_accessible

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.monitoring_role_arn

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  ca_cert_identifier         = var.ca_cert_identifier
  apply_immediately          = var.apply_immediately

  tags = var.tags
}
