resource "aws_db_instance" "replicas" {
  for_each = var.read_replicas

  identifier = each.key

  # Same-region replicas take the source identifier. A cross-region replica
  # needs the source ARN and a second provider, which this module does not do.
  replicate_source_db = aws_db_instance.instance.identifier

  instance_class = coalesce(each.value.instance_class, var.instance_class)
  multi_az       = each.value.multi_az

  # A Multi-AZ instance picks its own zones. Sending both is an API error.
  availability_zone = each.value.multi_az ? null : each.value.availability_zone

  publicly_accessible    = each.value.publicly_accessible
  vpc_security_group_ids = var.vpc_security_group_ids

  # Engine, version, storage size, and credentials come from the source.
  # Storage type and autoscaling can still differ per replica.
  storage_type          = var.storage_type
  max_allocated_storage = var.max_allocated_storage

  parameter_group_name = local.parameter_group_name
  option_group_name    = var.option_group_name

  # A replica needs backups of its own only to be the source of a
  # cascading replica.
  backup_retention_period = each.value.backup_retention_period

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.monitoring_role_arn

  deletion_protection        = var.deletion_protection
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  ca_cert_identifier         = var.ca_cert_identifier

  # RDS refuses a final snapshot of a read replica.
  skip_final_snapshot = true

  tags = var.tags
}
