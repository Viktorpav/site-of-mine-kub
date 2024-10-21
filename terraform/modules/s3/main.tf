# S3 bucket for Website
resource "aws_s3_bucket" "site_bucket" {
  bucket = var.domain_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site_bucket_encryption" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "site_bucket_cors" {
  bucket = aws_s3_bucket.site_bucket.id

  cors_rule {
    allowed_origins = [
      "https://${var.domain_name}",
      "https://www.${var.domain_name}",
    ]
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
  }
}

# Add similar blocks for other file types (.mp4, .avi, etc.)
resource "aws_s3_bucket_notification" "site_bucket_notification" {
  bucket = aws_s3_bucket.site_bucket.id

  lambda_function {
    lambda_function_arn = var.transcode_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".mp4"
  }

  lambda_function {
    lambda_function_arn = var.transcode_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ".avi"
  }
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "api-logs-bucket"
  tags = {
    Name        = "API CloudFront Logs Bucket"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_ownership_controls" "log_bucket_ownership" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_ownership]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
