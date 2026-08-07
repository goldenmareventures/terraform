# modules/ecs/cluster/variables.tf
variable "name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "container_insights" {
  description = "CloudWatch Container Insights level. enhanced costs more and adds per task and per service metrics."
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "disabled", "enhanced"], var.container_insights)
    error_message = "container_insights must be enabled, disabled, or enhanced."
  }
}

variable "capacity_providers" {
  description = "Capacity providers the cluster can use. FARGATE_SPOT is cheaper but a task can be stopped with two minutes notice."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Strategy used by a service that declares no strategy of its own. Set to an empty list to force every service to choose."
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number)
  }))
  default = [{ capacity_provider = "FARGATE", weight = 1 }]
}

variable "execute_command_configuration" {
  description = "Where ECS Exec session output is logged, and the key that encrypts it. Set to null to keep the AWS default."
  type = object({
    kms_key_id                     = optional(string)
    logging                        = optional(string, "DEFAULT")
    cloud_watch_log_group_name     = optional(string)
    cloud_watch_encryption_enabled = optional(bool)
    s3_bucket_name                 = optional(string)
    s3_key_prefix                  = optional(string)
    s3_bucket_encryption_enabled   = optional(bool)
  })
  default = null

  validation {
    condition     = var.execute_command_configuration == null || contains(["NONE", "DEFAULT", "OVERRIDE"], try(var.execute_command_configuration.logging, "DEFAULT"))
    error_message = "logging must be NONE, DEFAULT, or OVERRIDE."
  }
}

variable "service_connect_namespace" {
  description = "ARN or name of the Cloud Map namespace used by Service Connect when a service names none"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the cluster"
  type        = map(string)
  default     = {}
}
