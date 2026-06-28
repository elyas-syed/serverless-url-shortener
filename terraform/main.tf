locals {
  name_prefix = var.project_name
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
