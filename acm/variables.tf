variable "domain_name" {
  description = "Primary domain on the certificate, for example example.com or *.example.com"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional names on the certificate, for example [\"*.example.com\"]"
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route 53 hosted zone ID that receives the validation records. Must be authoritative for every name on the certificate."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}
