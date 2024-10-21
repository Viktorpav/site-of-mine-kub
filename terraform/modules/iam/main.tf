resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = var.s3_website_bucket.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal",
        Effect    = "Allow",
        Principal = { Service = "cloudfront.amazonaws.com" },
        Action    = "s3:GetObject",
        Resource  = ["${var.s3_website_bucket.arn}/*"],
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = [var.cloudfront_distribution]
          }
        }
      }
    ]
  })
}
