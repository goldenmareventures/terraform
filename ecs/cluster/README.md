# ECS Cluster Module

Terraform module for an ECS cluster with Fargate capacity providers, Container Insights,
and ECS Exec logging.

A cluster is shared. Create one cluster and point several `ecs/service` modules at it.

## Features

- Fargate and Fargate Spot capacity providers with a default strategy
- Container Insights, standard or enhanced
- ECS Exec session logging to CloudWatch or S3
- A default Cloud Map namespace for Service Connect

## Usage

### A plain cluster

```terraform
module "ecs_cluster" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecs/cluster?ref=v1.13.0"

  name = "app-prod"
  tags = local.tags
}
```

### Spot by default, with one on-demand task

`base` is the number of tasks placed on the first provider before the weights apply. This
keeps one task on Fargate and sends every extra task to Fargate Spot.

```terraform
module "ecs_cluster" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecs/cluster?ref=v1.13.0"

  name = "app-staging"

  default_capacity_provider_strategy = [
    { capacity_provider = "FARGATE", weight = 1, base = 1 },
    { capacity_provider = "FARGATE_SPOT", weight = 4 },
  ]

  tags = local.tags
}
```

### Enhanced insights and ECS Exec audit logs

```terraform
module "ecs_cluster" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecs/cluster?ref=v1.13.0"

  name               = "app-prod"
  container_insights = "enhanced"

  execute_command_configuration = {
    logging                    = "OVERRIDE"
    cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs_exec.name
  }

  tags = local.tags
}
```

## Inputs

| Name                                 | Type           | Default                                       | Description                                        |
| ------------------------------------ | -------------- | --------------------------------------------- | -------------------------------------------------- |
| `name`                               | `string`       | required                                      | Name of the cluster                                 |
| `container_insights`                 | `string`       | `"enabled"`                                   | `enabled`, `disabled`, or `enhanced`                |
| `capacity_providers`                 | `list(string)` | `["FARGATE", "FARGATE_SPOT"]`                 | Providers the cluster may use                       |
| `default_capacity_provider_strategy` | `list(object)` | `[{ capacity_provider = "FARGATE", weight = 1 }]` | Strategy for a service that declares none       |
| `execute_command_configuration`      | `object`       | `null`                                        | ECS Exec logging and encryption                     |
| `service_connect_namespace`          | `string`       | `null`                                        | Default Cloud Map namespace                         |
| `tags`                               | `map(string)`  | `{}`                                          | Tags applied to the cluster                         |

### execute_command_configuration

| Field                            | Type     | Default     | Description                                   |
| -------------------------------- | -------- | ----------- | --------------------------------------------- |
| `kms_key_id`                     | `string` | `null`      | Key that encrypts the session data            |
| `logging`                        | `string` | `"DEFAULT"` | `NONE`, `DEFAULT`, or `OVERRIDE`              |
| `cloud_watch_log_group_name`     | `string` | `null`      | Log group, used by `OVERRIDE` only            |
| `cloud_watch_encryption_enabled` | `bool`   | `null`      | Require an encrypted log group                |
| `s3_bucket_name`                 | `string` | `null`      | Bucket, used by `OVERRIDE` only               |
| `s3_key_prefix`                  | `string` | `null`      | Key prefix inside the bucket                  |
| `s3_bucket_encryption_enabled`   | `bool`   | `null`      | Require an encrypted bucket                   |

## Outputs

| Name   | Description                                        |
| ------ | -------------------------------------------------- |
| `arn`  | ARN of the cluster. Pass it to `ecs/service`.      |
| `id`   | ID of the cluster                                  |
| `name` | Name of the cluster, used in CloudWatch dimensions |

## Notes

- The module does not create EC2 capacity providers. It covers Fargate only.
- `enhanced` Container Insights costs more than `enabled`. It adds per task and per
  service metrics.
- `log_configuration` is sent only when `logging` is `OVERRIDE`. AWS rejects it otherwise.
