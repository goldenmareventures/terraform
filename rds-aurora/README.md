# modules/rds-aurora/README.md
# Aurora Module

Terraform module for Amazon Aurora clusters. The module supports Aurora MySQL and Aurora PostgreSQL, provisioned instances and Serverless v2.

## Features

- Aurora MySQL and Aurora PostgreSQL from one module
- Provisioned instances or Serverless v2 scaling
- Master password managed in Secrets Manager
- Cluster and instance parameter groups
- Enhanced Monitoring role created on demand
- Performance Insights
- Storage encryption and IAM database authentication
- Restore from a snapshot

## Usage

### Aurora MySQL, writer and one reader

```terraform
module "orders_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds-aurora?ref=v1.0.0"

  cluster_identifier = "orders-prod"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.05.2"
  database_name      = "orders"
  master_username    = "admin"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  instances = {
    "orders-prod-1" = { promotion_tier = 0 }
    "orders-prod-2" = { promotion_tier = 1 }
  }

  instance_class = "db.r6g.large"

  backup_retention_period         = 14
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  monitoring_interval             = 30

  tags = local.tags
}
```

### Aurora PostgreSQL

```terraform
module "app_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds-aurora?ref=v1.0.0"

  cluster_identifier = "app-prod"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  database_name      = "app"
  master_username    = "postgres"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  instances = {
    "app-prod-1" = { promotion_tier = 0 }
  }

  instance_class = "db.r6g.large"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = local.tags
}
```

### Serverless v2

Set `serverlessv2_scaling`. The module then uses `db.serverless` for every instance and ignores `instance_class`.

```terraform
module "reporting_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds-aurora?ref=v1.0.0"

  cluster_identifier = "reporting-dev"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  database_name      = "reporting"
  master_username    = "postgres"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  serverlessv2_scaling = {
    min_capacity = 0.5
    max_capacity = 4
  }

  instances = {
    "reporting-dev-1" = {}
  }

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = local.tags
}
```

### Custom parameter groups

Pass the family when you pass parameters. The module does not guess the family from the engine version.

```terraform
module "orders_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds-aurora?ref=v1.0.0"

  cluster_identifier = "orders-prod"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.05.2"
  master_username    = "admin"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  instances = { "orders-prod-1" = {} }

  cluster_parameter_group_family = "aurora-mysql8.0"
  cluster_parameters = [
    { name = "character_set_server", value = "utf8mb4", apply_method = "pending-reboot" },
    { name = "time_zone", value = "UTC" }
  ]

  instance_parameter_group_family = "aurora-mysql8.0"
  instance_parameters = [
    { name = "slow_query_log", value = "1" },
    { name = "long_query_time", value = "1" }
  ]

  tags = local.tags
}
```

### Reading the managed master password

```terraform
data "aws_secretsmanager_secret_version" "db" {
  secret_id = module.orders_db.master_user_secret_arn
}

locals {
  db_password = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_identifier | Identifier for the cluster | string | - | yes |
| engine | aurora-mysql or aurora-postgresql | string | - | yes |
| engine_version | Engine version | string | - | yes |
| master_username | Master username | string | - | yes |
| database_name | Initial database name | string | null | no |
| port | Cluster port | number | 3306 or 5432 | no |
| manage_master_user_password | Manage the password in Secrets Manager | bool | true | no |
| master_password | Master password when not managed | string | null | no |
| master_user_secret_kms_key_id | KMS key for the managed secret | string | null | no |
| create_subnet_group | Create a subnet group | bool | true | no |
| subnet_group_name | Subnet group name | string | null | no |
| subnet_ids | Subnets for the created subnet group | list(string) | [] | no |
| vpc_security_group_ids | Security groups for the cluster | list(string) | [] | no |
| availability_zones | Availability zones | list(string) | null | no |
| publicly_accessible | Make instances public | bool | false | no |
| instances | Map of instances by identifier | map(object) | {} | no |
| instance_class | Default instance class | string | db.t4g.medium | no |
| serverlessv2_scaling | Serverless v2 scaling | object | null | no |
| cluster_parameter_group_family | Cluster parameter group family | string | null | no |
| cluster_parameters | Cluster parameters | list(object) | [] | no |
| cluster_parameter_group_name | Existing cluster parameter group | string | null | no |
| instance_parameter_group_family | Instance parameter group family | string | null | no |
| instance_parameters | Instance parameters | list(object) | [] | no |
| instance_parameter_group_name | Existing instance parameter group | string | null | no |
| backup_retention_period | Backup retention in days | number | 7 | no |
| preferred_backup_window | Backup window in UTC | string | null | no |
| preferred_maintenance_window | Maintenance window in UTC | string | null | no |
| copy_tags_to_snapshot | Copy tags to snapshots | bool | true | no |
| backtrack_window | Backtrack seconds, MySQL only | number | 0 | no |
| snapshot_identifier | Snapshot to restore from | string | null | no |
| skip_final_snapshot | Skip the final snapshot | bool | false | no |
| final_snapshot_identifier | Final snapshot name | string | null | no |
| storage_encrypted | Encrypt storage | bool | true | no |
| kms_key_id | KMS key for storage | string | null | no |
| iam_database_authentication_enabled | Enable IAM auth | bool | false | no |
| deletion_protection | Enable deletion protection | bool | true | no |
| apply_immediately | Apply changes immediately | bool | false | no |
| allow_major_version_upgrade | Allow major upgrades | bool | false | no |
| auto_minor_version_upgrade | Allow minor upgrades | bool | true | no |
| ca_cert_identifier | CA certificate identifier | string | null | no |
| enabled_cloudwatch_logs_exports | Logs to export | list(string) | [] | no |
| performance_insights_enabled | Enable Performance Insights | bool | true | no |
| performance_insights_retention_period | Retention in days | number | 7 | no |
| performance_insights_kms_key_id | KMS key for Performance Insights | string | null | no |
| monitoring_interval | Enhanced Monitoring seconds | number | 0 | no |
| monitoring_role_arn | Existing monitoring role | string | null | no |
| tags | Tags to apply | map(string) | {} | no |

### Instance object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| instance_class | Overrides the module instance_class | string | null |
| promotion_tier | Failover priority, 0 is highest | number | 1 |
| availability_zone | Availability zone for this instance | string | null |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | Cluster identifier |
| cluster_arn | ARN of the cluster |
| cluster_resource_id | Resource ID for IAM auth policies |
| cluster_endpoint | Writer endpoint |
| cluster_reader_endpoint | Reader endpoint |
| cluster_port | Port |
| database_name | Initial database name |
| master_username | Master username |
| master_user_secret_arn | ARN of the managed password secret |
| instance_endpoints | Map of identifier to endpoint |
| instance_identifiers | List of instance identifiers |
| subnet_group_name | Subnet group in use |
| cluster_parameter_group_name | Cluster parameter group in use |
| monitoring_role_arn | Enhanced Monitoring role in use |

## Notes

### Instance map, not count

`instances` is a map keyed by instance identifier. A map keeps state addresses stable. If you use a count and remove a middle instance, every later instance shifts index and Terraform replaces it. Add and remove map keys instead.

### Log exports differ by engine

Aurora MySQL accepts `audit`, `error`, `general`, and `slowquery`. Aurora PostgreSQL accepts `postgresql`. The module does not validate this. A wrong value fails at apply time with an API error.

### Backtrack is MySQL only

The module sends `backtrack_window` only when the engine is `aurora-mysql`. Set it to 0 to disable. Backtrack is not compatible with Serverless v2.

### Parameter group family

You must set the family when you pass parameters. The module does not derive it from `engine_version`. A MySQL version string such as `8.0.mysql_aurora.3.05.2` maps to family `aurora-mysql8.0`, and Postgres `15.4` maps to `aurora-postgresql15`. Both parameter groups use `create_before_destroy`, so a family change replaces the group without an ordering failure.

### Serverless v2

Set `serverlessv2_scaling` to use Serverless v2. Every instance then uses the `db.serverless` class and `instance_class` is ignored. You still declare each instance in the `instances` map. A `min_capacity` of 0 requires a recent AWS provider and enables auto pause together with `seconds_until_auto_pause`.

### Ignored changes

The cluster ignores changes to `snapshot_identifier` and `availability_zones`. A restored cluster keeps `snapshot_identifier` set, and without the ignore every later plan wants to rebuild the cluster. AWS also returns availability zones in an order that does not match your input, which causes a permanent diff.

### Deletion protection

`deletion_protection` defaults to true and `skip_final_snapshot` defaults to false. A destroy fails until you turn deletion protection off in a separate apply. This is deliberate. Set both to a lower setting for short-lived development clusters only.