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
