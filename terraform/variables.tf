variable "aws_region" {
  description = "Primary AWS region for regional resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short project name used in resource naming."
  type        = string
  default     = "url-shortener"
}

variable "auth_mode" {
  description = "API auth mode: open (demo) or api_key (production)."
  type        = string
  default     = "open"

  validation {
    condition     = contains(["open", "api_key"], var.auth_mode)
    error_message = "auth_mode must be open or api_key."
  }
}

variable "rate_limit_per_minute" {
  description = "Maximum create-link requests per IP per minute in open auth mode."
  type        = number
  default     = 5
}

variable "default_link_ttl_days" {
  description = "Default expiration for new links when expires_in_days is omitted."
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Custom domain for the shortener (leave empty to use CloudFront default domain)."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for domain_name (required when domain_name is set)."
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Attach AWS WAF to CloudFront (~$5+/month minimum when enabled). See docs/cost.md."
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "WAF rate-based rule: max requests per 5 minutes per IP before block (only when enable_waf is true)."
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Common resource tags."
  type        = map(string)
  default = {
    Project = "url-shortener"
    Managed = "terraform"
  }
}
