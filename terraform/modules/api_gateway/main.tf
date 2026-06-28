resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "create_link" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri          = var.create_link_arn
  integration_method       = "POST"
  payload_format_version   = "2.0"
}

resource "aws_apigatewayv2_integration" "redirect" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri          = var.redirect_arn
  integration_method       = "POST"
  payload_format_version   = "2.0"
}

resource "aws_apigatewayv2_integration" "get_analytics" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri          = var.get_analytics_arn
  integration_method       = "POST"
  payload_format_version   = "2.0"
}

resource "aws_apigatewayv2_route" "create_link" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/links"
  target    = "integrations/${aws_apigatewayv2_integration.create_link.id}"
}

resource "aws_apigatewayv2_route" "get_analytics" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /api/links/{slug}"
  target    = "integrations/${aws_apigatewayv2_integration.get_analytics.id}"
}

resource "aws_apigatewayv2_route" "delete_link" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "DELETE /api/links/{slug}"
  target    = "integrations/${aws_apigatewayv2_integration.get_analytics.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.redirect.id}"
}

resource "aws_apigatewayv2_route" "redirect" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /{slug}"
  target    = "integrations/${aws_apigatewayv2_integration.redirect.id}"
}

resource "aws_apigatewayv2_route" "redirect_head" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "HEAD /{slug}"
  target    = "integrations/${aws_apigatewayv2_integration.redirect.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
  tags        = var.tags

  default_route_settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }

  depends_on = [
    aws_apigatewayv2_route.create_link,
    aws_apigatewayv2_route.get_analytics,
    aws_apigatewayv2_route.delete_link,
    aws_apigatewayv2_route.health,
    aws_apigatewayv2_route.redirect,
    aws_apigatewayv2_route.redirect_head,
  ]
}

resource "aws_lambda_permission" "create_link" {
  statement_id  = "AllowAPIGatewayCreateLink"
  action        = "lambda:InvokeFunction"
  function_name = var.create_link_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "redirect" {
  statement_id  = "AllowAPIGatewayRedirect"
  action        = "lambda:InvokeFunction"
  function_name = var.redirect_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_analytics" {
  statement_id  = "AllowAPIGatewayGetAnalytics"
  action        = "lambda:InvokeFunction"
  function_name = var.get_analytics_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
