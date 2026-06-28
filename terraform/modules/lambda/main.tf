data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project_name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [
      var.links_table_arn,
      var.rate_limits_table_arn,
    ]
  }

  statement {
    actions   = ["sqs:SendMessage"]
    resources = [var.click_events_queue_arn]
  }

  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.click_events_queue_arn]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name   = "${var.project_name}-lambda-permissions"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

locals {
  common_env = {
    LINKS_TABLE_NAME        = var.links_table_name
    RATE_LIMITS_TABLE_NAME  = var.rate_limits_table_name
    CLICK_EVENTS_QUEUE_URL  = var.click_events_queue_url
    AUTH_MODE               = var.auth_mode
    RATE_LIMIT_PER_MINUTE   = tostring(var.rate_limit_per_minute)
    DEFAULT_LINK_TTL_DAYS   = tostring(var.default_link_ttl_days)
    BASE_URL                = var.base_url
  }
}

resource "aws_lambda_function" "create_link" {
  function_name    = "${var.project_name}-create-link"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_paths["create_link"]
  source_code_hash = var.lambda_source_hashes["create_link"]
  timeout          = 10
  memory_size      = 256

  environment {
    variables = local.common_env
  }

  tags = var.tags
}

resource "aws_lambda_function" "redirect" {
  function_name    = "${var.project_name}-redirect"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_paths["redirect"]
  source_code_hash = var.lambda_source_hashes["redirect"]
  timeout          = 10
  memory_size      = 256

  environment {
    variables = local.common_env
  }

  tags = var.tags
}

resource "aws_lambda_function" "get_analytics" {
  function_name    = "${var.project_name}-get-analytics"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_paths["get_analytics"]
  source_code_hash = var.lambda_source_hashes["get_analytics"]
  timeout          = 10
  memory_size      = 256

  environment {
    variables = local.common_env
  }

  tags = var.tags
}

resource "aws_lambda_function" "click_tracker" {
  function_name    = "${var.project_name}-click-tracker"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_paths["click_tracker"]
  source_code_hash = var.lambda_source_hashes["click_tracker"]
  timeout          = 10
  memory_size      = 256

  environment {
    variables = local.common_env
  }

  tags = var.tags
}

resource "aws_lambda_event_source_mapping" "click_tracker" {
  event_source_arn = var.click_events_queue_arn
  function_name    = aws_lambda_function.click_tracker.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_cloudwatch_log_group" "create_link" {
  name              = "/aws/lambda/${aws_lambda_function.create_link.function_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "redirect" {
  name              = "/aws/lambda/${aws_lambda_function.redirect.function_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "get_analytics" {
  name              = "/aws/lambda/${aws_lambda_function.get_analytics.function_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "click_tracker" {
  name              = "/aws/lambda/${aws_lambda_function.click_tracker.function_name}"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "click_tracker_dlq" {
  alarm_name          = "${var.project_name}-click-tracker-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Click tracker Lambda errors"

  dimensions = {
    FunctionName = aws_lambda_function.click_tracker.function_name
  }

  tags = var.tags
}
