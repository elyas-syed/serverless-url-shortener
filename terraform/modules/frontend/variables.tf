variable "project_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "web_root" {
  description = "Path to static web assets on disk."
  type        = string
  default     = "../../web"
}
