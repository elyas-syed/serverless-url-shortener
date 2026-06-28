output "click_events_queue_url" {
  value = aws_sqs_queue.click_events.url
}

output "click_events_queue_arn" {
  value = aws_sqs_queue.click_events.arn
}

output "click_events_dlq_arn" {
  value = aws_sqs_queue.click_events_dlq.arn
}
