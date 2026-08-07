variable "lambda_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_path" {
  description = "Path to Lambda directory relative to the current terraform directory"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for the Lambda function"
  type        = string
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

variable "memory_size" {
  description = "Amount of memory in MB for the Lambda function"
  type        = number
  default     = 128
}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "notification_rule_arn" {
  description = "ARN of the EventBridge notification rule to add as a trigger"
  type        = string
  default     = null
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "prod"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 3
}

variable "runtime" {
  description = "Runtime environment for the Lambda function"
  type        = string
  default     = "nodejs24.x"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "index.handler"
}

variable "dead_letter_target_arn" {
  description = "SQS queue or SNS topic ARN for failed asynchronous invocations. Null disables the DLQ."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Customer managed KMS key ARN for environment variable encryption. Null uses the AWS managed key."
  type        = string
  default     = null
}

variable "tracing_mode" {
  description = "X-Ray tracing mode: Active, PassThrough, or null to disable."
  type        = string
  default     = null

  validation {
    condition     = var.tracing_mode == null || contains(["Active", "PassThrough"], coalesce(var.tracing_mode, "Active"))
    error_message = "tracing_mode must be Active, PassThrough, or null."
  }
}

variable "reserved_concurrent_executions" {
  description = "Function level concurrency limit. Null uses the unreserved account pool. 0 stops all invocations."
  type        = number
  default     = null
}

variable "vpc_subnet_ids" {
  description = "Subnet IDs to attach the function to. Empty keeps the function outside a VPC."
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the VPC attachment. Required when vpc_subnet_ids is set."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
