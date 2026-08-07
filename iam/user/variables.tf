# modules/iam/user/variables.tf
variable "user_name" {
  description = "Name of the IAM user"
  type        = string
}

variable "path" {
  description = "Path for the IAM user"
  type        = string
  default     = "/"
}

variable "create_access_key" {
  description = "Create access key for the user"
  type        = bool
  default     = true
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policy names to policy documents"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the user"
  type        = map(string)
  default     = {}
}
