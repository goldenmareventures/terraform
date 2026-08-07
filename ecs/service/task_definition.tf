# modules/ecs/service/task_definition.tf
data "aws_region" "current" {}

locals {
  family         = coalesce(var.family, var.name)
  log_group_name = coalesce(var.log_group_name, "/ecs/${var.name}")

  # A container keeps its own log_configuration. Otherwise it writes to the
  # managed log group, unless the module was told not to create one.
  log_configurations = {
    for cname, c in var.containers : cname => (
      c.log_configuration != null ? {
        logDriver = c.log_configuration.log_driver
        options   = c.log_configuration.options
        } : var.create_log_group ? {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.log_group_name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = cname
        }
      } : null
    )
  }

  container_definitions = [
    for cname, c in var.containers : {
      name                   = cname
      image                  = c.image
      cpu                    = c.cpu
      memory                 = c.memory
      memoryReservation      = c.memory_reservation
      essential              = c.essential
      command                = c.command
      entryPoint             = c.entrypoint
      workingDirectory       = c.working_directory
      user                   = c.user
      stopTimeout            = c.stop_timeout
      readonlyRootFilesystem = c.readonly_root_filesystem
      logConfiguration       = local.log_configurations[cname]

      # awsvpc networking requires hostPort to equal containerPort.
      portMappings = [
        for p in c.port_mappings : {
          containerPort = p.container_port
          hostPort      = p.container_port
          protocol      = p.protocol
          name          = p.name
          appProtocol   = p.app_protocol
        }
      ]

      environment = [for k, v in c.environment : { name = k, value = v }]
      secrets     = [for k, v in c.secrets : { name = k, valueFrom = v }]

      mountPoints = [
        for m in c.mount_points : {
          sourceVolume  = m.source_volume
          containerPath = m.container_path
          readOnly      = m.read_only
        }
      ]

      dependsOn = [
        for d in c.container_depends_on : {
          containerName = d.container_name
          condition     = d.condition
        }
      ]

      healthCheck = c.health_check == null ? null : {
        command     = c.health_check.command
        interval    = c.health_check.interval
        timeout     = c.health_check.timeout
        retries     = c.health_check.retries
        startPeriod = c.health_check.start_period
      }
    }
  ]
}

resource "aws_cloudwatch_log_group" "task" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_group_kms_key_id

  tags = merge(var.tags, { Name = local.log_group_name })
}

resource "aws_ecs_task_definition" "task" {
  family                   = local.family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn
  container_definitions    = jsonencode(local.container_definitions)

  runtime_platform {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = var.operating_system_family
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != null ? [1] : []

    content {
      size_in_gib = var.ephemeral_storage_size
    }
  }

  dynamic "volume" {
    for_each = var.volumes

    content {
      name = volume.key

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs != null ? [volume.value.efs] : []

        content {
          file_system_id = efs_volume_configuration.value.file_system_id

          # AWS rejects a root_directory other than "/" when an access point is
          # used. The access point already sets the path.
          root_directory = efs_volume_configuration.value.access_point_id != null ? "/" : efs_volume_configuration.value.root_directory

          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.access_point_id != null ? [1] : []

            content {
              access_point_id = efs_volume_configuration.value.access_point_id
              iam             = efs_volume_configuration.value.iam
            }
          }
        }
      }
    }
  }

  tags = merge(var.tags, { Name = local.family })
}
