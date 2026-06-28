variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "links_table_name" {
  type = string
}

variable "links_table_arn" {
  type = string
}

variable "rate_limits_table_name" {
  type = string
}

variable "rate_limits_table_arn" {
  type = string
}

variable "click_events_queue_arn" {
  type = string
}

variable "click_events_queue_url" {
  type = string
}

variable "auth_mode" {
  type = string
}

variable "rate_limit_per_minute" {
  type = number
}

variable "default_link_ttl_days" {
  type = number
}

variable "base_url" {
  type    = string
  default = ""
}

variable "lambda_source_hashes" {
  description = "Map of function name to zip content hash."
  type        = map(string)
}

variable "lambda_zip_paths" {
  description = "Map of function name to zip file path."
  type        = map(string)
}
