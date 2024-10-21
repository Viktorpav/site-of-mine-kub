terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }

  # Required version of Terraform
  required_version = "~> 1.9.5"
}

# AWS provider with region and profile set to the
# region and aws_profile variables
provider "aws" {
  region  = var.region
  profile = var.aws_profile

  endpoints {
    sts = "https://sts.${var.region}.amazonaws.com"
  }
}


// The S3 module to store tfstate file in S3 backet as a backup 
module "s3" {
  source                  = "./modules/s3"
  prefix                  = var.prefix
  domain_name             = var.domain_name
  transcode_function_arn  = module.lambda.transcode_function_arn
  cloudfront_distribution = module.cloudfront.cloudfront_distribution.arn
}

module "lambda" {
  source      = "./modules/lambda"
  prefix      = var.prefix
  domain_name = var.domain_name
}

module "cloudfront" {
  source                 = "./modules/cloudfront"
  prefix                 = var.prefix
  domain_name            = var.domain_name
  domain_certificate_arn = module.acm.domain_certificate_arn
  prem_api_id            = module.apigateway.prem_api_id
  s3_log_bucket          = module.s3.s3_log_bucket
}

module "acm" {
  source      = "./modules/acm"
  prefix      = var.prefix
  domain_name = var.domain_name
}

module "iam" {
  source                  = "./modules/iam"
  prefix                  = var.prefix
  domain_name             = var.domain_name
  s3_website_bucket       = module.s3.s3_website_bucket
  cloudfront_distribution = module.cloudfront.cloudfront_distribution.arn
}

module "apigateway" {
  source                  = "./modules/apigateway"
  prefix                  = var.prefix
  domain_name             = var.domain_name
  cloudfront_distribution = module.cloudfront.cloudfront_distribution.arn
}
