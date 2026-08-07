# modules/ecs/service/variables.tf
variable "name" {
  description = "Name of the service. Also used as a prefix for the task family, the IAM roles, the log group, and the security group."
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster that runs the service. A bare cluster name also works."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC that holds the managed security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the tasks run in. Use private subnets unless assign_public_ip is true."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet."
  }
}

# Task definition
variable "family" {
  description = "Task definition family. Defaults to name."
  type        = string
  default     = null
}

variable "cpu" {
  description = "CPU units for the whole task. Fargate accepts 256, 512, 1024, 2048, 4096, 8192, and 16384."
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Memory in MiB for the whole task. Fargate allows only certain values for each cpu size."
  type        = string
  default     = "512"
}

variable "cpu_architecture" {
  description = "CPU architecture of the task. ARM64 is cheaper, but the image must be built for it."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "operating_system_family" {
  description = "Operating system family of the task"
  type        = string
  default     = "LINUX"
}

variable "ephemeral_storage_size" {
  description = "Task scratch space in GiB, from 21 to 200. Fargate gives 20 GiB free, so set this only when more is needed."
  type        = number
  default     = null

  validation {
    condition     = var.ephemeral_storage_size == null || try(var.ephemeral_storage_size >= 21 && var.ephemeral_storage_size <= 200, false)
    error_message = "ephemeral_storage_size must be between 21 and 200."
  }
}

variable "containers" {
  description = "Containers keyed by container name. The key becomes the container name and the log stream prefix."
  type = map(object({
    image                    = string
    cpu                      = optional(number)
    memory                   = optional(number)
    memory_reservation       = optional(number)
    essential                = optional(bool, true)
    command                  = optional(list(string))
    entrypoint               = optional(list(string))
    working_directory        = optional(string)
    user                     = optional(string)
    stop_timeout             = optional(number)
    readonly_root_filesystem = optional(bool)

    # Plain values. Anything sensitive belongs in secrets.
    environment = optional(map(string), {})

    # Container variable name mapped to a Secrets Manager or SSM Parameter
    # Store ARN. The execution role must be allowed to read it.
    secrets = optional(map(string), {})

    port_mappings = optional(list(object({
      container_port = number
      protocol       = optional(string, "tcp")
      # name and app_protocol are needed by Service Connect only.
      name         = optional(string)
      app_protocol = optional(string)
    })), [])

    health_check = optional(object({
      command      = list(string)
      interval     = optional(number, 30)
      timeout      = optional(number, 5)
      retries      = optional(number, 3)
      start_period = optional(number, 60)
    }))

    mount_points = optional(list(object({
      source_volume  = string
      container_path = string
      read_only      = optional(bool, false)
    })), [])

    # Start order for sidecars. condition is START, COMPLETE, SUCCESS, or HEALTHY.
    container_depends_on = optional(list(object({
      container_name = string
      condition      = string
    })), [])

    # Overrides the managed awslogs configuration for this container.
    log_configuration = optional(object({
      log_driver = string
      options    = optional(map(string), {})
    }))
  }))

  validation {
    condition     = length(var.containers) > 0
    error_message = "containers must define at least one container."
  }
}

variable "volumes" {
  description = "Task volumes keyed by volume name. A volume with no efs block is scratch space shared between containers."
  type = map(object({
    efs = optional(object({
      file_system_id          = string
      root_directory          = optional(string, "/")
      transit_encryption      = optional(string, "ENABLED")
      transit_encryption_port = optional(number)
      access_point_id         = optional(string)
      iam                     = optional(string, "DISABLED")
    }))
  }))
  default = {}
}

# Logging
variable "create_log_group" {
  description = "Create a CloudWatch log group and point every container at it. Set to false when each container sets its own log_configuration."
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the log group. Defaults to /ecs/<name>."
  type        = string
  default     = null
}

variable "log_retention_in_days" {
  description = "Days CloudWatch keeps the logs. Use 0 to keep them forever."
  type        = number
  default     = 30
}

variable "log_group_kms_key_id" {
  description = "ARN of the KMS key that encrypts the log group"
  type        = string
  default     = null
}

# IAM
variable "execution_role_arn" {
  description = "Existing execution role. The module creates one when this is null. The execution role pulls the image and writes the logs."
  type        = string
  default     = null
}

variable "execution_role_policy_arns" {
  description = "Extra managed policies for the created execution role"
  type        = list(string)
  default     = []
}

variable "execution_role_secret_arns" {
  description = "Secrets Manager, SSM parameter, and KMS key ARNs the execution role may read. Needed by every entry in containers.secrets."
  type        = list(string)
  default     = []
}

variable "task_role_arn" {
  description = "Existing task role. The module creates one when this is null. The task role is what the application code uses."
  type        = string
  default     = null
}

variable "task_role_policy_arns" {
  description = "Managed policies for the created task role"
  type        = list(string)
  default     = []
}

variable "task_role_inline_policies" {
  description = "Inline policies for the created task role, keyed by policy name. Each value is a policy JSON document."
  type        = map(string)
  default     = {}
}

# Service
variable "create_service" {
  description = "Create the ECS service. Set to false to publish only a task definition, for example for a scheduled task."
  type        = bool
  default     = true
}

variable "desired_count" {
  description = "Number of tasks to keep running. With autoscaling set, use the same value as autoscaling.min_capacity."
  type        = number
  default     = 1
}

variable "launch_type" {
  description = "Launch type used when capacity_provider_strategy is empty"
  type        = string
  default     = "FARGATE"
}

variable "capacity_provider_strategy" {
  description = "Split of tasks across capacity providers. Leave empty to use launch_type. Use base on FARGATE and weight on FARGATE_SPOT to keep a stable floor."
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number)
  }))
  default = []
}

variable "platform_version" {
  description = "Fargate platform version. Leave null for LATEST."
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "Give each task a public IP. Needed when the tasks run in public subnets and there is no NAT gateway."
  type        = bool
  default     = false
}

variable "security_group" {
  description = "Managed security group. It opens one ingress rule for each container port from the given sources. Set to null to use only security_group_ids."
  type = object({
    # Defaults to every container port found in containers.
    ingress_ports              = optional(list(number))
    ingress_security_group_ids = optional(list(string), [])
    ingress_cidr_blocks        = optional(list(string), [])
    egress_cidr_blocks         = optional(list(string), ["0.0.0.0/0"])
  })
  default = {}
}

variable "security_group_ids" {
  description = "Extra security groups to attach, in addition to the managed one"
  type        = list(string)
  default     = []
}

variable "load_balancers" {
  description = "Target groups the service registers with, keyed by a short name. Use target_type ip on the target group, because Fargate uses awsvpc networking."
  type = map(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = {}
}

variable "service_registries" {
  description = "Cloud Map service discovery registration"
  type = object({
    registry_arn   = string
    container_name = optional(string)
    container_port = optional(number)
    port           = optional(number)
  })
  default = null
}

variable "deployment_minimum_healthy_percent" {
  description = "Percent of desired_count that must stay running during a deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Percent of desired_count allowed to run during a deployment. 200 starts the new tasks before stopping the old ones."
  type        = number
  default     = 200
}

variable "deployment_circuit_breaker" {
  description = "Stop a deployment that never reaches a steady state, and roll it back. Set to null to turn the check off."
  type = object({
    enable   = optional(bool, true)
    rollback = optional(bool, true)
  })
  default = {}
}

variable "health_check_grace_period_seconds" {
  description = "Seconds the load balancer health check is ignored after a task starts. Applies only when load_balancers is set."
  type        = number
  default     = null
}

variable "enable_execute_command" {
  description = "Allow aws ecs execute-command to open a shell in a running task. The module adds the needed task role permissions."
  type        = bool
  default     = false
}

variable "enable_ecs_managed_tags" {
  description = "Let ECS add its own cluster and service tags to each task"
  type        = bool
  default     = true
}

variable "propagate_tags" {
  description = "Where task tags come from"
  type        = string
  default     = "SERVICE"

  validation {
    condition     = contains(["NONE", "SERVICE", "TASK_DEFINITION"], var.propagate_tags)
    error_message = "propagate_tags must be NONE, SERVICE, or TASK_DEFINITION."
  }
}

variable "availability_zone_rebalancing" {
  description = "Let ECS move tasks to even them out across availability zones. Leave null to keep the AWS default."
  type        = string
  default     = null

  validation {
    condition     = var.availability_zone_rebalancing == null || contains(["ENABLED", "DISABLED"], coalesce(var.availability_zone_rebalancing, "ENABLED"))
    error_message = "availability_zone_rebalancing must be ENABLED or DISABLED."
  }
}

variable "wait_for_steady_state" {
  description = "Make terraform apply wait until the deployment finishes. Slow, but a failed rollout then fails the apply."
  type        = bool
  default     = false
}

variable "force_new_deployment" {
  description = "Start a new deployment on every apply. Use it when the image tag stays the same."
  type        = bool
  default     = false
}

# Autoscaling
variable "autoscaling" {
  description = "Application Auto Scaling for the task count. Set to null to keep a fixed count."
  type = object({
    min_capacity  = number
    max_capacity  = number
    cpu_target    = optional(number, 70)
    memory_target = optional(number)

    # resource_label is "<alb_arn_suffix>/<target_group_arn_suffix>".
    request_count = optional(object({
      target         = number
      resource_label = string
    }))

    scale_in_cooldown  = optional(number, 300)
    scale_out_cooldown = optional(number, 60)
  })
  default = null
}

variable "tags" {
  description = "Tags applied to every resource the module creates"
  type        = map(string)
  default     = {}
}
