variable "prefix" {}
variable "domain_name" {}
variable "s3_website_bucket" {
  type = object({
    name = string
    arn  = string
  })
}
variable "cloudfront_distribution" {}
