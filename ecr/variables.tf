# modules/ecr/variables.tf
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type (AES256 or KMS). Ignored if kms_key_arn is set."
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption (forces encryption_type to KMS)"
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "JSON lifecycle policy document"
  type        = string
  default     = null
}

variable "repository_policy" {
  description = "JSON repository policy document (for cross-account access, etc.)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
