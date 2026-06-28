resource "aws_sqs_queue" "click_events_dlq" {
  name                      = "${var.project_name}-click-events-dlq"
  message_retention_seconds = 1209600

  tags = merge(var.tags, {
    Name = "${var.project_name}-click-events-dlq"
  })
}

resource "aws_sqs_queue" "click_events" {
  name                       = "${var.project_name}-click-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.click_events_dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-click-events"
  })
}
