variable "log_group_name" {
  type        = string
  description = "Cloudwatch log group name"
}

variable "retention_in_days" {
  type        = number
  description = "Number of days to retain logs in the log group"
  default     = 14
}

variable "kms_key_id" {
  description = "Customer managed KMS key ARN for log encryption. Null uses the AWS managed key."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
