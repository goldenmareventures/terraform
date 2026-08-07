# vpc/variables.tf
variable "name" {
  description = "Name of the VPC. Used as the Name tag and as a prefix for every resource the module creates."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the VPC (e.g. 10.0.0.0/16)"
  type        = string
}

variable "instance_tenancy" {
  description = "Tenancy of instances launched into the VPC"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "instance_tenancy must be default or dedicated."
  }
}

# DNS
variable "enable_dns_support" {
  description = "Enable DNS resolution in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Assign DNS hostnames to instances. Required by RDS and by interface endpoints with private DNS."
  type        = bool
  default     = true
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Request an Amazon-provided /56 IPv6 CIDR block for the VPC"
  type        = bool
  default     = false
}

variable "manage_default_security_group" {
  description = "Take ownership of the default security group and remove all of its rules"
  type        = bool
  default     = true
}

# Subnets
variable "public_subnets" {
  description = "Public subnets keyed by a short name, usually the AZ letter. Any subnet here gets a route to the internet gateway."
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool, true)
    name                    = optional(string)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "private_subnets" {
  description = "Private subnets keyed by a short name. Set route_to_nat = false for an isolated tier, such as databases, that must not reach the internet."
  type = map(object({
    cidr_block        = string
    availability_zone = string
    route_to_nat      = optional(bool, true)
    name              = optional(string)
    tags              = optional(map(string), {})
  }))
  default = {}
}

# NAT
variable "nat_gateway_mode" {
  description = "NAT gateways to create: none, single (one shared gateway), or per_az (one per public subnet)"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be none, single, or per_az."
  }
}

# Endpoints
variable "gateway_endpoints" {
  description = "Gateway VPC endpoints to create, attached to every route table in the VPC. Only s3 and dynamodb exist as gateway endpoints."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for s in var.gateway_endpoints : contains(["s3", "dynamodb"], s)])
    error_message = "gateway_endpoints entries must be s3 or dynamodb."
  }
}

# Flow logs
variable "flow_log" {
  description = "Flow log configuration. Null disables flow logs. With cloud-watch-logs the module creates the log group and the delivery role."
  type = object({
    destination_type         = optional(string, "cloud-watch-logs")
    s3_bucket_arn            = optional(string)
    retention_in_days        = optional(number, 30)
    kms_key_arn              = optional(string)
    traffic_type             = optional(string, "ALL")
    max_aggregation_interval = optional(number, 600)
  })
  default = null

  validation {
    condition     = var.flow_log == null || try(contains(["cloud-watch-logs", "s3"], var.flow_log.destination_type), false)
    error_message = "flow_log.destination_type must be cloud-watch-logs or s3."
  }

  validation {
    condition     = var.flow_log == null || try(var.flow_log.destination_type != "s3" || var.flow_log.s3_bucket_arn != null, false)
    error_message = "flow_log.s3_bucket_arn is required when flow_log.destination_type is s3."
  }

  validation {
    condition     = var.flow_log == null || try(contains(["ACCEPT", "REJECT", "ALL"], var.flow_log.traffic_type), false)
    error_message = "flow_log.traffic_type must be ACCEPT, REJECT, or ALL."
  }
}

variable "tags" {
  description = "Tags applied to every resource the module creates"
  type        = map(string)
  default     = {}
}
