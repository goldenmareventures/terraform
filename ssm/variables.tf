variable "ssm_variables" {
  description = "Map of SSM variables to create"
  type = map(object({
    name        = string
    description = optional(string, "")
    type        = optional(string, "SecureString")
    value       = string
  }))

  validation {
    condition = alltrue([
      for k, v in var.ssm_variables :
      contains(["String", "StringList", "SecureString"], v.type)
    ])
    error_message = "All parameter types must be String, StringList, or SecureString."
  }
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}
