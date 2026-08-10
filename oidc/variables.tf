variable "url" {
  description = "Issuer URL of the identity provider, including the https:// scheme. For example https://token.actions.githubusercontent.com."
  type        = string

  validation {
    condition     = startswith(var.url, "https://")
    error_message = "url must include the https:// scheme."
  }
}

variable "client_id_list" {
  description = "Audiences the provider may issue tokens for. sts.amazonaws.com is the audience AWS expects for role assumption."
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "thumbprint_list" {
  description = "Certificate thumbprints of the issuer. Leave empty for a well-known provider such as GitHub, which AWS validates against its own trust store."
  type        = list(string)
  default     = []
}

variable "subjects" {
  description = "Subject claims allowed to assume a role through this provider, used to build the assume_role_policy output. For GitHub, entries look like repo:OWNER/REPO:ref:refs/heads/main. A '*' in any entry switches the condition to StringLike. Leave empty to skip the subject condition entirely, which trusts every subject the issuer will ever mint."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}
