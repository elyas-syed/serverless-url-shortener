output "links_table_name" {
  value = aws_dynamodb_table.links.name
}

output "links_table_arn" {
  value = aws_dynamodb_table.links.arn
}

output "rate_limits_table_name" {
  value = aws_dynamodb_table.rate_limits.name
}

output "rate_limits_table_arn" {
  value = aws_dynamodb_table.rate_limits.arn
}
