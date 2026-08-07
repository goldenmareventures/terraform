variable "email_templates" {
  description = "Map of email templates"
  type = map(object({
    name    = string
    subject = string
    html    = string
    text    = optional(string)
  }))
  default = {}
}

variable "configuration_sets" {
  description = "Map of SES configuration sets"
  type = map(object({
    name                       = string
    reputation_metrics_enabled = optional(bool)
    sending_enabled            = optional(bool)
  }))
  default = {}
}

variable "cloudwatch_destinations" {
  description = "Map of CloudWatch event destinations"
  type = map(object({
    name                  = string
    configuration_set_key = string # References key in configuration_sets
    enabled               = optional(bool)
    matching_types        = list(string)
    cloudwatch = object({
      default_value  = string
      dimension_name = string
      value_source   = string
    })
  }))
  default = {}
}

variable "sns_destinations" {
  description = "Map of SNS event destinations"
  type = map(object({
    name                  = string
    configuration_set_key = string # References key in configuration_sets
    enabled               = optional(bool)
    matching_types        = list(string)
    topic_arn             = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}
