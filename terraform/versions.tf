terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Uncomment after running terraform/bootstrap.
  # backend "s3" {
  #   bucket         = "your-unique-url-shortener-tf-state-bucket"
  #   key            = "url-shortener/terraform.tfstate"
  #   region         = "us-east-1"
  #   use_lockfile   = true
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
