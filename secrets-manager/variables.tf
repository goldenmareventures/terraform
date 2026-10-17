variable "secrets" {
  description = "Map of Secrets Manager secrets to create. Set external = true for a secret whose value a human sets outside Terraform."
  type = map(object({
    name        = string
    description = optional(string, "")
    external    = optional(bool, false)
    policy      = optional(string)
  }))

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.external || contains(nonsensitive(keys(var.secret_values)), k)
    ])
    error_message = "Every secret with external = false must have a value in secret_values under the same key."
  }
}

variable "secret_values" {
  description = "Values for the generated secrets, keyed by the same keys as secrets"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "kms_key_id" {
  description = "Customer managed KMS key ARN or ID for secret encryption. Null uses the AWS managed aws/secretsmanager key."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days AWS waits before it deletes a secret. 0 deletes immediately."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 or between 7 and 30."
  }
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}
