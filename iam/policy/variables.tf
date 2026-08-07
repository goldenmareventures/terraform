variable "policy_name" {
  description = "Name of the IAM policy"
  type        = string
}

variable "description" {
  description = "Description of the IAM policy"
  type        = string
  default     = ""
}

variable "path" {
  description = "Path for the IAM policy"
  type        = string
  default     = "/"
}

variable "policy_document" {
  description = "IAM policy document (JSON string)"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
