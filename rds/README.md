# modules/rds/README.md
# RDS Module

Terraform module for a single Amazon RDS instance. The module supports MySQL, MariaDB, and
PostgreSQL, with optional Multi-AZ and same-region read replicas.

Use `rds-aurora` for Aurora. Aurora is a cluster with its own options and does not fit here.

## Features

- MySQL, MariaDB, and PostgreSQL from one module
- Single-AZ or Multi-AZ
- Same-region read replicas
- Master password managed in Secrets Manager
- gp3, io1, io2, and storage autoscaling
- Parameter group created on demand
- Enhanced Monitoring role created on demand
- Performance Insights
- Storage encryption and IAM database authentication
- Restore from a snapshot

## Usage

### MySQL, Multi-AZ

```terraform
module "orders_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds?ref=v1.13.0"

  identifier     = "orders-prod"
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.m6g.large"
  database_name  = "orders"
  username       = "admin"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  allocated_storage     = 100
  max_allocated_storage = 500
  multi_az              = true

  backup_retention_period         = 14
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  monitoring_interval             = 30
  performance_insights_enabled    = true

  tags = local.tags
}
```

### PostgreSQL with a read replica

```terraform
module "app_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds?ref=v1.13.0"

  identifier     = "app-prod"
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.m6g.large"
  database_name  = "app"
  username       = "postgres"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  allocated_storage = 200

  read_replicas = {
    "app-prod-replica-1" = { instance_class = "db.m6g.large" }
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = local.tags
}
```

### Development instance

```terraform
module "dev_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds?ref=v1.13.0"

  identifier     = "app-dev"
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t4g.micro"
  database_name  = "app"
  username       = "postgres"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = local.tags
}
```

### Custom parameters

Pass the family when you pass parameters. The module does not guess the family from the
engine version.

```terraform
module "orders_db" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//rds?ref=v1.13.0"

  identifier     = "orders-prod"
  engine         = "mysql"
  engine_version = "8.0.35"
  username       = "admin"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db.id]

  parameter_group_family = "mysql8.0"
  parameters = [
    { name = "character_set_server", value = "utf8mb4", apply_method = "pending-reboot" },
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
| identifier | Identifier for the DB instance | string | - | yes |
| engine | mysql, mariadb, or postgres | string | - | yes |
| engine_version | Engine version | string | - | yes |
| username | Master username | string | - | yes |
| instance_class | Instance class | string | db.t4g.micro | no |
| database_name | Initial database name | string | null | no |
| port | Instance port | number | 3306 or 5432 | no |
| manage_master_user_password | Manage the password in Secrets Manager | bool | true | no |
| password | Master password when not managed | string | null | no |
| master_user_secret_kms_key_id | KMS key for the managed secret | string | null | no |
| allocated_storage | Storage in GiB | number | 20 | no |
| max_allocated_storage | Autoscaling limit in GiB, 0 disables | number | 0 | no |
| storage_type | gp2, gp3, io1, io2, or standard | string | gp3 | no |
| iops | Provisioned IOPS | number | null | no |
| storage_throughput | gp3 throughput in MiBps | number | null | no |
| storage_encrypted | Encrypt storage | bool | true | no |
| kms_key_id | KMS key for storage | string | null | no |
| create_subnet_group | Create a subnet group | bool | true | no |
| subnet_group_name | Subnet group name | string | null | no |
| subnet_ids | Subnets for the created subnet group | list(string) | [] | no |
| vpc_security_group_ids | Security groups for the instance | list(string) | [] | no |
| publicly_accessible | Give the instance a public address | bool | false | no |
| multi_az | Run a standby in a second zone | bool | false | no |
| availability_zone | Zone for a single-AZ instance | string | null | no |
| read_replicas | Map of replicas by identifier | map(object) | {} | no |
| parameter_group_family | Parameter group family | string | null | no |
| parameters | DB parameters | list(object) | [] | no |
| parameter_group_name | Existing parameter group | string | null | no |
| option_group_name | Existing option group | string | null | no |
| backup_retention_period | Backup retention in days | number | 7 | no |
| backup_window | Backup window in UTC | string | null | no |
| maintenance_window | Maintenance window in UTC | string | null | no |
| copy_tags_to_snapshot | Copy tags to snapshots | bool | true | no |
| delete_automated_backups | Delete automated backups on destroy | bool | true | no |
| snapshot_identifier | Snapshot to restore from | string | null | no |
| skip_final_snapshot | Skip the final snapshot | bool | false | no |
| final_snapshot_identifier | Final snapshot name | string | null | no |
| iam_database_authentication_enabled | Enable IAM auth | bool | false | no |
| deletion_protection | Enable deletion protection | bool | true | no |
| apply_immediately | Apply changes immediately | bool | false | no |
| allow_major_version_upgrade | Allow major upgrades | bool | false | no |
| auto_minor_version_upgrade | Allow minor upgrades | bool | true | no |
| ca_cert_identifier | CA certificate identifier | string | null | no |
| enabled_cloudwatch_logs_exports | Logs to export | list(string) | [] | no |
| performance_insights_enabled | Enable Performance Insights | bool | false | no |
| performance_insights_retention_period | Retention in days | number | 7 | no |
| performance_insights_kms_key_id | KMS key for Performance Insights | string | null | no |
| monitoring_interval | Enhanced Monitoring seconds | number | 0 | no |
| monitoring_role_arn | Existing monitoring role | string | null | no |
| tags | Tags to apply | map(string) | {} | no |

### Read replica object

| Name | Description | Type | Default |
|------|-------------|------|---------|
| instance_class | Overrides the module instance_class | string | null |
| multi_az | Run this replica Multi-AZ | bool | false |
| availability_zone | Zone for a single-AZ replica | string | null |
| publicly_accessible | Give the replica a public address | bool | false |
| backup_retention_period | Backups on the replica, days | number | 0 |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | Instance identifier |
| instance_arn | ARN of the instance |
| instance_resource_id | Resource ID for IAM auth policies |
| endpoint | Address and port |
| address | Hostname |
| port | Port |
| database_name | Initial database name |
| username | Master username |
| master_user_secret_arn | ARN of the managed password secret |
| replica_endpoints | Map of replica identifier to endpoint |
| replica_identifiers | List of replica identifiers |
| subnet_group_name | Subnet group in use |
| parameter_group_name | Parameter group in use |
| monitoring_role_arn | Enhanced Monitoring role in use |

## Notes

### Aurora is a different module

`rds-aurora` covers Aurora MySQL and Aurora PostgreSQL. Aurora uses a cluster resource, cluster
parameter groups, reader endpoints, and Serverless v2 scaling. None of that applies here.

### Replica map, not count

`read_replicas` is a map keyed by replica identifier. A map keeps state addresses stable. If you
use a count and remove a middle replica, every later replica shifts index and Terraform replaces
it. Add and remove map keys instead.

### Read replicas are same-region only

The module sets `replicate_source_db` to the source identifier, which AWS accepts for a replica
in the same region. A cross-region replica needs the source ARN and a second provider alias, so
declare it in the calling project.

A replica inherits engine, version, storage size, and credentials from its source. The module
sends only the fields a replica can change: class, zone, public access, storage type,
autoscaling limit, and its own backup retention.

### Performance Insights is off by default

Performance Insights is not supported on micro and small instance classes, such as
`db.t4g.micro`. The module default is `false` so a small instance applies without an error. Turn
it on for anything larger.

### Multi-AZ and availability_zone

The module drops `availability_zone` when `multi_az` is true. AWS picks the zones for a Multi-AZ
instance and rejects a request that sends both.

### gp3 IOPS and throughput

Below 400 GiB, gp3 gives a fixed 3000 IOPS and 125 MiBps and AWS rejects `iops` and
`storage_throughput`. Leave both null until the volume is larger. `io1` and `io2` always need
`iops`.

### Log exports differ by engine

MySQL and MariaDB accept `audit`, `error`, `general`, and `slowquery`. PostgreSQL accepts
`postgresql` and `upgrade`. The module does not validate this. A wrong value fails at apply time
with an API error.

### Parameter group family

You must set the family when you pass parameters. The module does not derive it from
`engine_version`. MySQL `8.0.35` maps to family `mysql8.0`, MariaDB `10.11.6` to `mariadb10.11`,
and Postgres `16.3` to `postgres16`. The group uses `create_before_destroy`, so a family change
replaces the group without an ordering failure.

The module ships no default parameters. Pass what you need.

### Option groups

The module attaches an existing option group but does not create one. Option groups are needed
for a small number of engine features, such as the MySQL audit plugin. Declare the group in the
calling project and pass `option_group_name`.

### Ignored changes

The instance ignores changes to `snapshot_identifier`. A restored instance keeps it set, and
without the ignore every later plan wants to rebuild the instance.

### Deletion protection

`deletion_protection` defaults to true and `skip_final_snapshot` defaults to false. A destroy
fails until you turn deletion protection off in a separate apply. This is deliberate. Set both
to a lower setting for short-lived development instances only.
