output "links_table_name" {
  description = "DynamoDB table storing short links."
  value       = module.dynamodb.links_table_name
}

output "rate_limits_table_name" {
  description = "DynamoDB table for per-IP create rate limiting."
  value       = module.dynamodb.rate_limits_table_name
}

output "click_events_queue_url" {
  description = "SQS queue URL for async click tracking."
  value       = module.sqs.click_events_queue_url
}

output "api_endpoint" {
  description = "Direct API Gateway endpoint (bypasses CloudFront)."
  value       = module.api_gateway.api_endpoint
}

output "app_url" {
  description = "Public URL for the web UI and short links."
  value       = module.cloudfront.app_url
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.distribution_domain_name
}
