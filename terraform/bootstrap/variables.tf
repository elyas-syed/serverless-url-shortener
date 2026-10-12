variable "aws_region" {
  description = "AWS region for the state backend."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the Terraform state bucket. A random 8-character hex suffix is appended for global uniqueness."
  type        = string
  default     = "url-shortener-tf-state"
}

variable "force_destroy" {
  description = "Allow Terraform to delete the state bucket even if it still contains objects. Used by make bootstrap-destroy."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to bootstrap resources."
  type        = map(string)
  default = {
    Project = "url-shortener"
    Managed = "terraform"
  }
}
