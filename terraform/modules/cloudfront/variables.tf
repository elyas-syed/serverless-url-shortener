variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "hosted_zone_id" {
  type    = string
  default = ""
}

variable "api_domain_name" {
  description = "API Gateway domain for the api origin (without https://)."
  type        = string
}

variable "frontend_bucket_name" {
  type = string
}

variable "frontend_bucket_arn" {
  type = string
}

variable "frontend_bucket_regional_domain_name" {
  type = string
}
