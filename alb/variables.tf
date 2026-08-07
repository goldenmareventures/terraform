# modules/alb/variables.tf
variable "name" {
  description = "Name of the load balancer. Also used as a prefix for the security group and for target groups that do not set their own name."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC that holds the target groups and the managed security group"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the load balancer runs in. At least two, in different availability zones."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets in different availability zones."
  }
}

variable "internal" {
  description = "Place the load balancer on private addresses only"
  type        = bool
  default     = false
}

variable "ip_address_type" {
  description = "Address type of the load balancer"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_type must be ipv4 or dualstack."
  }
}

# Security groups
variable "security_group" {
  description = "Managed security group. It opens one ingress rule for each listener port from the given CIDRs. Set to null to use only security_group_ids."
  type = object({
    ingress_cidr_blocks      = optional(list(string), ["0.0.0.0/0"])
    ingress_ipv6_cidr_blocks = optional(list(string), [])
    egress_cidr_blocks       = optional(list(string), ["0.0.0.0/0"])
  })
  default = {}
}

variable "security_group_ids" {
  description = "Extra security groups to attach, in addition to the managed one"
  type        = list(string)
  default     = []
}

# Load balancer attributes
variable "idle_timeout" {
  description = "Seconds a connection can be idle before the load balancer closes it"
  type        = number
  default     = 60
}

variable "enable_http2" {
  description = "Accept HTTP/2 connections"
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Refuse to delete the load balancer until this is turned off"
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Drop request headers that do not match RFC 7230. Turn this on unless a client sends headers with underscores."
  type        = bool
  default     = false
}

variable "preserve_host_header" {
  description = "Forward the client Host header unchanged instead of rewriting it"
  type        = bool
  default     = false
}

variable "desync_mitigation_mode" {
  description = "How the load balancer handles requests that pose a desync risk"
  type        = string
  default     = "defensive"

  validation {
    condition     = contains(["monitor", "defensive", "strictest"], var.desync_mitigation_mode)
    error_message = "desync_mitigation_mode must be monitor, defensive, or strictest."
  }
}

variable "access_logs" {
  description = "Access logs to S3. The bucket policy must already allow the ELB log delivery account to write to it."
  type = object({
    bucket  = string
    prefix  = optional(string)
    enabled = optional(bool, true)
  })
  default = null
}

variable "connection_logs" {
  description = "Connection logs to S3. These record TLS and client connection detail, not requests."
  type = object({
    bucket  = string
    prefix  = optional(string)
    enabled = optional(bool, true)
  })
  default = null
}

# Target groups
variable "target_groups" {
  description = "Target groups keyed by a short name. The key is how listeners and rules refer to the group."
  type = map(object({
    name                          = optional(string)
    port                          = optional(number, 80)
    protocol                      = optional(string, "HTTP")
    protocol_version              = optional(string, "HTTP1")
    target_type                   = optional(string, "instance")
    deregistration_delay          = optional(number, 300)
    slow_start                    = optional(number)
    load_balancing_algorithm_type = optional(string)

    health_check = optional(object({
      enabled             = optional(bool, true)
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      matcher             = optional(string, "200")
      interval            = optional(number, 30)
      timeout             = optional(number, 5)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
    }), {})

    stickiness = optional(object({
      type            = optional(string, "lb_cookie")
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string)
      enabled         = optional(bool, true)
    }))

    # Static targets. Leave empty when ECS, an autoscaling group, or another
    # service registers its own targets.
    targets = optional(map(object({
      id   = string
      port = optional(number)
    })), {})

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for tg in var.target_groups : contains(["HTTP", "HTTPS"], tg.protocol)])
    error_message = "target_groups protocol must be HTTP or HTTPS."
  }

  validation {
    condition     = alltrue([for tg in var.target_groups : contains(["instance", "ip", "lambda"], tg.target_type)])
    error_message = "target_groups target_type must be instance, ip, or lambda."
  }

  validation {
    condition     = alltrue([for tg in var.target_groups : contains(["HTTP1", "HTTP2", "GRPC"], tg.protocol_version)])
    error_message = "target_groups protocol_version must be HTTP1, HTTP2, or GRPC."
  }
}

# Listeners
variable "listeners" {
  description = "Listeners keyed by a short name. The key is how listener_rules refer to the listener."
  type = map(object({
    port                        = number
    protocol                    = optional(string, "HTTP")
    certificate_arn             = optional(string)
    additional_certificate_arns = optional(list(string), [])
    ssl_policy                  = optional(string)

    default_action = object({
      type = optional(string, "forward")

      # forward
      target_group_key = optional(string)
      # Weighted forward, for a blue/green or canary split. Keys are target group keys.
      target_group_weights = optional(map(number))

      redirect = optional(object({
        host        = optional(string, "#{host}")
        path        = optional(string, "/#{path}")
        port        = optional(string, "#{port}")
        protocol    = optional(string, "#{protocol}")
        query       = optional(string, "#{query}")
        status_code = optional(string, "HTTP_301")
      }))

      fixed_response = optional(object({
        status_code  = optional(string, "404")
        content_type = optional(string, "text/plain")
        message_body = optional(string)
      }))
    })

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for l in var.listeners : contains(["HTTP", "HTTPS"], l.protocol)])
    error_message = "listeners protocol must be HTTP or HTTPS."
  }

  validation {
    condition     = alltrue([for l in var.listeners : l.protocol != "HTTPS" || l.certificate_arn != null])
    error_message = "listeners with protocol HTTPS require a certificate_arn."
  }

  validation {
    condition     = alltrue([for l in var.listeners : contains(["forward", "redirect", "fixed-response"], l.default_action.type)])
    error_message = "listeners default_action.type must be forward, redirect, or fixed-response."
  }

  validation {
    condition = alltrue([
      for l in var.listeners : l.default_action.type != "forward" ||
      l.default_action.target_group_key != null || l.default_action.target_group_weights != null
    ])
    error_message = "listeners with a forward default_action need target_group_key or target_group_weights."
  }
}

variable "listener_rules" {
  description = "Listener rules keyed by a short name. A rule needs at least one condition, and priorities must be unique within a listener."
  type = map(object({
    listener_key = string
    priority     = number

    action = object({
      type = optional(string, "forward")

      target_group_key     = optional(string)
      target_group_weights = optional(map(number))

      redirect = optional(object({
        host        = optional(string, "#{host}")
        path        = optional(string, "/#{path}")
        port        = optional(string, "#{port}")
        protocol    = optional(string, "#{protocol}")
        query       = optional(string, "#{query}")
        status_code = optional(string, "HTTP_301")
      }))

      fixed_response = optional(object({
        status_code  = optional(string, "404")
        content_type = optional(string, "text/plain")
        message_body = optional(string)
      }))
    })

    conditions = object({
      path_patterns        = optional(list(string))
      host_headers         = optional(list(string))
      http_request_methods = optional(list(string))
      source_ips           = optional(list(string))
      # Header name -> accepted values.
      http_headers = optional(map(list(string)))
      # Query string key -> accepted value.
      query_strings = optional(map(string))
    })
  }))
  default = {}

  validation {
    condition     = alltrue([for r in var.listener_rules : contains(["forward", "redirect", "fixed-response"], r.action.type)])
    error_message = "listener_rules action.type must be forward, redirect, or fixed-response."
  }

  validation {
    condition = alltrue([
      for r in var.listener_rules : length([
        for v in [
          r.conditions.path_patterns, r.conditions.host_headers, r.conditions.http_request_methods,
          r.conditions.source_ips, r.conditions.http_headers, r.conditions.query_strings
        ] : v if v != null
      ]) > 0
    ])
    error_message = "each listener_rules entry needs at least one condition."
  }
}

variable "tags" {
  description = "Tags applied to every resource the module creates"
  type        = map(string)
  default     = {}
}
