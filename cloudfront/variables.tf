variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Enable IPv6"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
  default     = null
}

variable "default_root_object" {
  description = "Default root object (e.g., index.html)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "aliases" {
  description = "Alternate domain names (CNAMEs)"
  type        = list(string)
  default     = []
}

variable "web_acl_id" {
  description = "WAF Web ACL ID"
  type        = string
  default     = null
}

variable "http_version" {
  description = "HTTP version (http1.1, http2, http2and3, http3)"
  type        = string
  default     = "http2and3"
}

variable "origins" {
  description = "List of origins"
  type = list(object({
    domain_name               = string
    origin_id                 = string
    origin_path               = optional(string)
    origin_access_control_key = optional(string)
    origin_access_control_id  = optional(string)
    connection_attempts       = optional(number)
    connection_timeout        = optional(number)
    custom_origin_config = optional(object({
      http_port                = optional(number, 80)
      https_port               = optional(number, 443)
      origin_protocol_policy   = string
      origin_ssl_protocols     = optional(list(string), ["TLSv1.2"])
      origin_keepalive_timeout = optional(number)
      origin_read_timeout      = optional(number)
    }))
    s3_origin_config = optional(object({
      origin_access_identity = string
    }))
    custom_headers = optional(list(object({
      name  = string
      value = string
    })))
    origin_shield = optional(object({
      enabled              = bool
      origin_shield_region = string
    }))
  }))
}

variable "origin_groups" {
  description = "List of origin groups for failover"
  type = list(object({
    origin_id             = string
    failover_status_codes = list(number)
    primary_origin_id     = string
    secondary_origin_id   = string
  }))
  default = []
}

variable "default_cache_behavior" {
  description = "Default cache behavior configuration"
  type = object({
    target_origin_id           = string
    viewer_protocol_policy     = string
    allowed_methods            = optional(list(string), ["GET", "HEAD"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    compress                   = optional(bool, true)
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 86400)
    max_ttl                    = optional(number, 31536000)
    forward_query_string       = optional(bool, false)
    query_string_cache_keys    = optional(list(string))
    forward_headers            = optional(list(string))
    forward_cookies            = optional(string, "none")
    forward_cookies_whitelist  = optional(list(string))
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })))
    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })))
  })
}

variable "ordered_cache_behaviors" {
  description = "Ordered cache behaviors (processed in order)"
  type = list(object({
    path_pattern               = string
    target_origin_id           = string
    viewer_protocol_policy     = string
    allowed_methods            = optional(list(string), ["GET", "HEAD"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    compress                   = optional(bool, true)
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 86400)
    max_ttl                    = optional(number, 31536000)
    forward_query_string       = optional(bool, false)
    query_string_cache_keys    = optional(list(string))
    forward_headers            = optional(list(string))
    forward_cookies            = optional(string, "none")
    forward_cookies_whitelist  = optional(list(string))
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })))
    lambda_function_associations = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })))
  }))
  default = []
}

variable "custom_error_responses" {
  description = "Custom error response configurations"
  type = list(object({
    error_code            = number
    error_caching_min_ttl = optional(number)
    response_code         = optional(number)
    response_page_path    = optional(string)
  }))
  default = []
}

variable "geo_restriction" {
  description = "Geo restriction configuration"
  type = object({
    restriction_type = optional(string, "none")
    locations        = optional(list(string), [])
  })
  default = {}
}

variable "viewer_certificate" {
  description = "Viewer certificate configuration"
  type = object({
    acm_certificate_arn      = optional(string)
    minimum_protocol_version = optional(string, "TLSv1.2_2021")
    ssl_support_method       = optional(string, "sni-only")
  })
  default = {}
}

variable "logging_config" {
  description = "Access logging configuration"
  type = object({
    bucket          = string
    prefix          = optional(string)
    include_cookies = optional(bool, false)
  })
  default = null
}

variable "origin_access_controls" {
  description = "Origin Access Controls to create"
  type = map(object({
    name             = string
    description      = optional(string)
    origin_type      = optional(string, "s3")
    signing_behavior = optional(string, "always")
    signing_protocol = optional(string, "sigv4")
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to the distribution"
  type        = map(string)
  default     = {}
}
