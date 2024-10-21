output "s3_website_bucket" {
  value = {
    name = aws_s3_bucket.site_bucket.bucket
    arn  = aws_s3_bucket.site_bucket.arn
  }
}

output "s3_log_bucket" {
  value = aws_s3_bucket.log_bucket.bucket_domain_name
}
