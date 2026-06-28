locals {
  lambda_functions = ["create_link", "redirect", "get_analytics", "click_tracker"]
  lambda_zip_paths = {
    for fn in local.lambda_functions : fn => "${path.root}/../dist/${fn}.zip"
  }
  lambda_source_hashes = {
    for fn in local.lambda_functions : fn => filebase64sha256(local.lambda_zip_paths[fn])
  }

  base_url = var.domain_name != "" ? "https://${var.domain_name}" : ""

  api_domain_name = trimprefix(trimsuffix(module.api_gateway.api_endpoint, "/"), "https://")
}

module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  tags         = var.tags
}

module "sqs" {
  source = "./modules/sqs"

  project_name = var.project_name
  tags         = var.tags
}

module "lambda" {
  source = "./modules/lambda"

  project_name             = var.project_name
  tags                     = var.tags
  links_table_name         = module.dynamodb.links_table_name
  links_table_arn          = module.dynamodb.links_table_arn
  rate_limits_table_name   = module.dynamodb.rate_limits_table_name
  rate_limits_table_arn    = module.dynamodb.rate_limits_table_arn
  click_events_queue_arn   = module.sqs.click_events_queue_arn
  click_events_queue_url   = module.sqs.click_events_queue_url
  auth_mode                = var.auth_mode
  rate_limit_per_minute    = var.rate_limit_per_minute
  default_link_ttl_days    = var.default_link_ttl_days
  base_url                 = local.base_url
  lambda_zip_paths         = local.lambda_zip_paths
  lambda_source_hashes     = local.lambda_source_hashes
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name        = var.project_name
  tags                = var.tags
  create_link_arn     = module.lambda.create_link_arn
  redirect_arn        = module.lambda.redirect_arn
  get_analytics_arn   = module.lambda.get_analytics_arn
  throttle_rate_limit = var.rate_limit_per_minute
  throttle_burst_limit = var.rate_limit_per_minute
}

module "frontend" {
  source = "./modules/frontend"

  project_name = var.project_name
  tags         = var.tags
  web_root     = "${path.root}/../web"
}

module "cloudfront" {
  source = "./modules/cloudfront"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  project_name                         = var.project_name
  tags                                 = var.tags
  domain_name                          = var.domain_name
  hosted_zone_id                       = var.hosted_zone_id
  api_domain_name                      = local.api_domain_name
  frontend_bucket_name                 = module.frontend.bucket_name
  frontend_bucket_arn                  = module.frontend.bucket_arn
  frontend_bucket_regional_domain_name = module.frontend.bucket_regional_domain_name
}
