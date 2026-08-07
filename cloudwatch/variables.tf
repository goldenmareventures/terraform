variable "log_group_name" {
  type        = string
  description = "Cloudwatch log group name"
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain logs in the log group"
  default     = 14
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
