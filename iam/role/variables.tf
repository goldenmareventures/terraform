variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "description" {
  description = "Description of the role"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Assume role policy document (JSON)"
  type        = string
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

variable "max_session_duration" {
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}

variable "path" {
  description = "Path for the role"
  type        = string
  default     = "/"
}

variable "permissions_boundary" {
  description = "ARN of permissions boundary policy"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
