variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "create_link_arn" {
  type = string
}

variable "redirect_arn" {
  type = string
}

variable "get_analytics_arn" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "$default"
}

variable "throttle_rate_limit" {
  type    = number
  default = 5
}

variable "throttle_burst_limit" {
  type    = number
  default = 5
}
