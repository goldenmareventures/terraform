# modules/route53/variables.tf
variable "domain_name" {
  description = "Domain name for the hosted zone"
  type        = string
}

variable "force_destroy" {
  description = "Allow deletion of hosted zone even if it contains records"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone (null for public)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the the resources"
  type        = map(string)
  default     = {}
}

variable "records" {
  description = "Map of DNS records to create"
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = optional(list(string))
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool)
    }))
    set_identifier = optional(string)
    weighted_routing_policy = optional(object({
      weight = number
    }))
    latency_routing_policy = optional(object({
      region = string
    }))
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    failover_routing_policy = optional(object({
      type = string
    }))
    health_check_id = optional(string)
  }))
  default = {}
}
