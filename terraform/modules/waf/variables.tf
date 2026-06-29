variable "enable_waf" {
  description = "When true, attach an AWS WAF web ACL to the CloudFront distribution."
  type        = bool
  default     = false
}

variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution to associate with the web ACL."
  type        = string
}

variable "rate_limit" {
  description = "Maximum requests per 5-minute window per IP before WAF blocks (rate-based rule)."
  type        = number
  default     = 2000
}
