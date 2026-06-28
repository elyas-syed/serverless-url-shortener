output "create_link_arn" {
  value = aws_lambda_function.create_link.arn
}

output "create_link_name" {
  value = aws_lambda_function.create_link.function_name
}

output "redirect_arn" {
  value = aws_lambda_function.redirect.arn
}

output "redirect_name" {
  value = aws_lambda_function.redirect.function_name
}

output "get_analytics_arn" {
  value = aws_lambda_function.get_analytics.arn
}

output "get_analytics_name" {
  value = aws_lambda_function.get_analytics.function_name
}

output "click_tracker_arn" {
  value = aws_lambda_function.click_tracker.arn
}
