# ECS Service Module

Terraform module for a Fargate task definition and service, with IAM roles, a CloudWatch
log group, a managed security group, and target tracking autoscaling.

Containers are declared as a map keyed by container name, not as a JSON string. The module
builds the container definition JSON, so no `jsonencode` is needed in the calling project.

## Features

- Fargate task definition, X86_64 or ARM64, with EFS and scratch volumes
- Containers with environment values, secrets, health checks, mount points, and start order
- Execution role and task role, both created by default and both replaceable
- CloudWatch log group wired to every container that sets no log driver of its own
- Managed security group that opens one ingress rule for each container port
- Load balancer registration, Cloud Map registration, and a deployment circuit breaker
- Target tracking autoscaling on CPU, memory, and ALB request count
- ECS Exec, with the task role permissions added for you

## Usage

### A web service behind an ALB

The common layout. The ALB security group is the only ingress source, and the tasks run in
private subnets.

```terraform
module "api" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecs/service?ref=v1.13.0"

  name        = "api"
  cluster_arn = module.ecs_cluster.arn
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  cpu    = "512"
  memory = "1024"

  containers = {
    api = {
      image         = "${module.ecr.repository_url}:${var.image_tag}"
      port_mappings = [{ container_port = 8080 }]
      environment   = { NODE_ENV = "production" }
      health_check  = { command = ["CMD-SHELL", "curl -fs http://localhost:8080/healthz || exit 1"] }
    }
  }

  security_group = {
    ingress_security_group_ids = [module.alb.security_group_id]
  }

  load_balancers = {
    api = {
      target_group_arn = module.alb.target_group_arns["app"]
      container_name   = "api"
      container_port   = 8080
    }
  }

  health_check_grace_period_seconds = 60

  tags = local.tags
}
```

The matching target group must use `target_type = "ip"`, because Fargate uses `awsvpc`
networking.

### Secrets from Secrets Manager

`secrets` maps the container variable name to the ARN that holds the value. The execution
role reads it, so every ARN must also appear in `execution_role_secret_arns`. Add the KMS
key ARN to that list when the secret uses a customer managed key.

```terraform
module "api" {
  # ...

  containers = {
    api = {
      image = "${module.ecr.repository_url}:${var.image_tag}"
      secrets = {
        DB_PASSWORD = aws_secretsmanager_secret.db.arn
        API_KEY     = aws_ssm_parameter.api_key.arn
      }
    }
  }

  execution_role_secret_arns = [
    aws_secretsmanager_secret.db.arn,
    aws_ssm_parameter.api_key.arn,
  ]
}
```

### Autoscaling and Fargate Spot

`base` keeps two tasks on on-demand Fargate. Every task above that goes to Spot.

```terraform
module "api" {
  # ...

  desired_count = 2

  capacity_provider_strategy = [
    { capacity_provider = "FARGATE", weight = 1, base = 2 },
    { capacity_provider = "FARGATE_SPOT", weight = 3 },
  ]

  autoscaling = {
    min_capacity = 2
    max_capacity = 20
    cpu_target   = 60

    request_count = {
      target         = 1000
      resource_label = "${module.alb.arn_suffix}/${module.alb.target_group_arn_suffixes["app"]}"
    }
  }
}
```

### A sidecar and a shared volume

A volume with no `efs` block is scratch space that lives as long as the task. `mount_points`
and `container_depends_on` refer to it and to the other container by name.

```terraform
module "api" {
  # ...

  volumes = { tmp = {} }

  containers = {
    api = {
      image         = "${module.ecr.repository_url}:${var.image_tag}"
      port_mappings = [{ container_port = 8080 }]
      mount_points  = [{ source_volume = "tmp", container_path = "/var/run/app" }]
    }

    proxy = {
      image                = "nginx:1.27-alpine"
      essential            = false
      mount_points         = [{ source_volume = "tmp", container_path = "/var/run/app", read_only = true }]
      container_depends_on = [{ container_name = "api", condition = "HEALTHY" }]
    }
  }
}
```

### A task definition with no service

Use this for a job that EventBridge Scheduler or Step Functions runs with `RunTask`.

```terraform
module "report_job" {
  source = "git::ssh://git@bitbucket.org/desertwebdesigns/terraform-modules.git//ecs/service?ref=v1.13.0"

  name           = "nightly-report"
  cluster_arn    = module.ecs_cluster.arn
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  create_service = false

  containers = {
    job = {
      image   = "${module.ecr.repository_url}:${var.image_tag}"
      command = ["node", "scripts/report.js"]
    }
  }

  tags = local.tags
}
```

### ECS Exec for a shell in a running task

```terraform
module "api" {
  # ...
  enable_execute_command = true
}
```

```bash
aws ecs execute-command --cluster app-prod --task <task-id> \
  --container api --interactive --command "/bin/sh"
```

## Inputs

| Name                                 | Type           | Default    | Description                                             |
| ------------------------------------ | -------------- | ---------- | ------------------------------------------------------- |
| `name`                               | `string`       | required   | Service name, and the prefix for every other resource   |
| `cluster_arn`                        | `string`       | required   | Cluster that runs the service                           |
| `vpc_id`                             | `string`       | required   | VPC of the managed security group                       |
| `subnet_ids`                         | `list(string)` | required   | Subnets the tasks run in                                |
| `containers`                         | `map(object)`  | required   | Containers keyed by container name                      |
| `family`                             | `string`       | `null`     | Task family. Defaults to `name`.                        |
| `cpu`                                | `string`       | `"256"`    | CPU units for the whole task                            |
| `memory`                             | `string`       | `"512"`    | Memory in MiB for the whole task                        |
| `cpu_architecture`                   | `string`       | `"X86_64"` | `X86_64` or `ARM64`                                     |
| `operating_system_family`            | `string`       | `"LINUX"`  | Operating system family                                 |
| `ephemeral_storage_size`             | `number`       | `null`     | Scratch space in GiB, 21 to 200                         |
| `volumes`                            | `map(object)`  | `{}`       | Task volumes keyed by volume name                       |
| `create_log_group`                   | `bool`         | `true`     | Create the CloudWatch log group                         |
| `log_group_name`                     | `string`       | `null`     | Defaults to `/ecs/<name>`                               |
| `log_retention_in_days`              | `number`       | `30`       | Days CloudWatch keeps the logs                          |
| `log_group_kms_key_id`               | `string`       | `null`     | Key that encrypts the log group                         |
| `execution_role_arn`                 | `string`       | `null`     | Existing execution role. Null creates one.              |
| `execution_role_policy_arns`         | `list(string)` | `[]`       | Extra managed policies for the created execution role   |
| `execution_role_secret_arns`         | `list(string)` | `[]`       | Secret, parameter, and key ARNs the execution role reads |
| `task_role_arn`                      | `string`       | `null`     | Existing task role. Null creates one.                   |
| `task_role_policy_arns`              | `list(string)` | `[]`       | Managed policies for the created task role              |
| `task_role_inline_policies`          | `map(string)`  | `{}`       | Inline policies keyed by name, each a policy JSON       |
| `create_service`                     | `bool`         | `true`     | Create the service, not only the task definition        |
| `desired_count`                      | `number`       | `1`        | Tasks to keep running                                   |
| `launch_type`                        | `string`       | `"FARGATE"`| Used when `capacity_provider_strategy` is empty         |
| `capacity_provider_strategy`         | `list(object)` | `[]`       | Split of tasks across capacity providers                |
| `platform_version`                   | `string`       | `null`     | Fargate platform version                                |
| `assign_public_ip`                   | `bool`         | `false`    | Give each task a public IP                              |
| `security_group`                     | `object`       | `{}`       | Managed security group. Null skips it.                  |
| `security_group_ids`                 | `list(string)` | `[]`       | Extra security groups                                   |
| `load_balancers`                     | `map(object)`  | `{}`       | Target groups the service registers with                |
| `service_registries`                 | `object`       | `null`     | Cloud Map registration                                  |
| `deployment_minimum_healthy_percent` | `number`       | `100`      | Percent that stays running during a deployment          |
| `deployment_maximum_percent`         | `number`       | `200`      | Percent allowed to run during a deployment              |
| `deployment_circuit_breaker`         | `object`       | `{}`       | Stop and roll back a stuck deployment. Null turns it off. |
| `health_check_grace_period_seconds`  | `number`       | `null`     | Grace period, load balancer services only               |
| `enable_execute_command`             | `bool`         | `false`    | Allow `aws ecs execute-command`                         |
| `enable_ecs_managed_tags`            | `bool`         | `true`     | Let ECS add its own tags to each task                   |
| `propagate_tags`                     | `string`       | `"SERVICE"`| `NONE`, `SERVICE`, or `TASK_DEFINITION`                 |
| `availability_zone_rebalancing`      | `string`       | `null`     | `ENABLED` or `DISABLED`                                 |
| `wait_for_steady_state`              | `bool`         | `false`    | Make the apply wait for the deployment                  |
| `force_new_deployment`               | `bool`         | `false`    | Redeploy on every apply                                 |
| `autoscaling`                        | `object`       | `null`     | Target tracking autoscaling                             |
| `tags`                               | `map(string)`  | `{}`       | Tags applied to every created resource                  |

### containers

| Field                      | Type           | Default | Description                                            |
| -------------------------- | -------------- | ------- | ------------------------------------------------------ |
| `image`                    | `string`       | required| Image URI                                              |
| `cpu`                      | `number`       | `null`  | CPU units for this container                           |
| `memory`                   | `number`       | `null`  | Hard memory limit in MiB                               |
| `memory_reservation`       | `number`       | `null`  | Soft memory limit in MiB                               |
| `essential`                | `bool`         | `true`  | Stop the task when this container stops                |
| `command`                  | `list(string)` | `null`  | Overrides the image CMD                                |
| `entrypoint`               | `list(string)` | `null`  | Overrides the image ENTRYPOINT                         |
| `working_directory`        | `string`       | `null`  | Working directory inside the container                 |
| `user`                     | `string`       | `null`  | User the process runs as                               |
| `stop_timeout`             | `number`       | `null`  | Seconds before the container is killed                 |
| `readonly_root_filesystem` | `bool`         | `null`  | Mount the root filesystem read only                    |
| `environment`              | `map(string)`  | `{}`    | Plain values                                           |
| `secrets`                  | `map(string)`  | `{}`    | Variable name to Secrets Manager or SSM ARN            |
| `port_mappings`            | `list(object)` | `[]`    | `container_port`, `protocol`, `name`, `app_protocol`   |
| `health_check`             | `object`       | `null`  | `command`, `interval`, `timeout`, `retries`, `start_period` |
| `mount_points`             | `list(object)` | `[]`    | `source_volume`, `container_path`, `read_only`         |
| `container_depends_on`     | `list(object)` | `[]`    | `container_name`, `condition`                          |
| `log_configuration`        | `object`       | `null`  | `log_driver` and `options`, replacing the managed one  |

`condition` is `START`, `COMPLETE`, `SUCCESS`, or `HEALTHY`.

### volumes

| Field | Type     | Default | Description                                      |
| ----- | -------- | ------- | ------------------------------------------------ |
| `efs` | `object` | `null`  | EFS settings. Null gives task scoped scratch space. |

The `efs` object holds `file_system_id`, `root_directory`, `transit_encryption`,
`transit_encryption_port`, `access_point_id`, and `iam`.

### security_group

| Field                        | Type           | Default           | Description                                     |
| ---------------------------- | -------------- | ----------------- | ----------------------------------------------- |
| `ingress_ports`              | `list(number)` | every container port | Ports the rules open                         |
| `ingress_security_group_ids` | `list(string)` | `[]`              | Source security groups, usually the ALB group   |
| `ingress_cidr_blocks`        | `list(string)` | `[]`              | Source CIDRs                                    |
| `egress_cidr_blocks`         | `list(string)` | `["0.0.0.0/0"]`   | Destinations the tasks may reach                |

### autoscaling

| Field                | Type     | Default | Description                                           |
| -------------------- | -------- | ------- | ----------------------------------------------------- |
| `min_capacity`       | `number` | required| Lowest task count                                     |
| `max_capacity`       | `number` | required| Highest task count                                    |
| `cpu_target`         | `number` | `70`    | Target average CPU percent. Null skips the policy.    |
| `memory_target`      | `number` | `null`  | Target average memory percent                         |
| `request_count`      | `object` | `null`  | `target` and `resource_label`                         |
| `scale_in_cooldown`  | `number` | `300`   | Seconds before another scale in                       |
| `scale_out_cooldown` | `number` | `60`    | Seconds before another scale out                      |

`resource_label` is `"<alb_arn_suffix>/<target_group_arn_suffix>"`.

## Outputs

| Name                             | Description                                       |
| -------------------------------- | ------------------------------------------------- |
| `service_name`                   | Name of the service, or null                      |
| `service_id`                     | ID of the service, or null                        |
| `task_definition_arn`            | ARN of the task definition revision               |
| `task_definition_family`         | Family of the task definition                     |
| `task_definition_revision`       | Revision number                                   |
| `security_group_id`              | ID of the managed security group, or null         |
| `security_group_ids`             | Every security group attached to the tasks        |
| `execution_role_arn`             | Execution role in use, created or supplied        |
| `execution_role_name`            | Name of the created execution role, or null       |
| `task_role_arn`                  | Task role in use, created or supplied             |
| `task_role_name`                 | Name of the created task role, or null            |
| `log_group_name`                 | Name of the created log group, or null            |
| `autoscaling_target_resource_id` | Resource ID for extra scaling policies            |

## Notes

- Fargate only. The module always sets `awsvpc` networking and `FARGATE` compatibility.
- `cpu` and `memory` are strings, because Fargate accepts only a fixed set of pairs. See
  the AWS task size table before you change them.
- Terraform does not track the autoscaled task count. With `autoscaling` set, keep
  `desired_count` equal to `autoscaling.min_capacity`, or every apply pulls the service
  back down and autoscaling raises it again.
- A target group used in `load_balancers` needs `target_type = "ip"`.
- Every ARN in `containers.secrets` must also be in `execution_role_secret_arns`, or the
  task fails to start with a `ResourceInitializationError`.
- The module does not create the cluster. Use the `ecs/cluster` module.
- Blue/green and external deployment controllers are out of scope. The service always uses
  the rolling ECS controller.
