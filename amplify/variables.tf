variable "app_name" {
  description = "Name of the Amplify app"
  type        = string
}

variable "repository_url" {
  description = "Repository URL (GitHub, Bitbucket, GitLab)"
  type        = string
}

variable "service_role_arn" {
  description = "IAM service role ARN for Amplify"
  type        = string
}

variable "compute_role_arn" {
  description = "IAM compute role ARN for SSR"
  type        = string
  default     = null
}

variable "platform" {
  description = "Platform type (WEB or WEB_COMPUTE for SSR)"
  type        = string
  default     = "WEB_COMPUTE"
}

variable "oauth_token" {
  description = "OAuth token for repository access"
  type        = string
  sensitive   = true
  default     = null
}

variable "access_token" {
  description = "Github personal access token for repository access"
  type        = string
  sensitive   = true
  default     = null
}

variable "default_framework" {
  description = "Default framework for branches"
  type        = string
  default     = "Next.js - SSR"
}

variable "default_environment_variables" {
  description = "Default environment variables for all branches"
  type        = map(string)
  default     = {}
}

variable "custom_environment_variables" {
  description = "Custom environment variables to merge with defaults"
  type        = map(string)
  default     = {}
}

variable "custom_rules" {
  description = "List of custom redirect/rewrite rules"
  type = list(object({
    source = string
    status = string
    target = string
  }))
  default = []
}

variable "branches" {
  description = "Map of branches to create"
  type = map(object({
    display_name          = optional(string)
    framework             = optional(string)
    stage                 = optional(string)
    enable_auto_build     = optional(bool)
    environment_variables = optional(map(string))
  }))
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = null
}

variable "enable_auto_sub_domain" {
  description = "Enable automatic subdomain creation"
  type        = bool
  default     = false
}

variable "wait_for_verification" {
  description = "Wait for domain verification"
  type        = bool
  default     = false
}

variable "sub_domains" {
  description = "List of subdomains to configure"
  type = list(object({
    branch_name = string
    prefix      = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
