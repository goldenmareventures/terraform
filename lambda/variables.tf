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

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
