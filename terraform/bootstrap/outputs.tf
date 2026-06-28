output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "backend_config" {
  description = "Copy these values into terraform/backend.tf after bootstrap apply."
  value = {
    bucket         = aws_s3_bucket.terraform_state.bucket
    key            = "url-shortener/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
  }
}
