data "aws_region" "current" {}

resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access_control" {
  name                              = var.domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name              = "${var.domain_name}.s3.${data.aws_region.current.name}.amazonaws.com"
    origin_id                = var.domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access_control.id
  }

  origin {
    domain_name = "${var.prem_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_id   = "APIGateway"
    origin_path = "/api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern     = "api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "APIGateway"


    cache_policy_id          = aws_cloudfront_cache_policy.minimal_cache_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_origin_request_policy.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.domain_name # This should be your S3 origin

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.function.arn
    }
  }

  default_root_object = ""
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"


  aliases = [
    var.domain_name,
    "www.${var.domain_name}",
    "api.${var.domain_name}"
  ]

  logging_config {
    bucket          = var.s3_log_bucket
    include_cookies = false
    prefix          = "cloudfront/"
  }

  viewer_certificate {
    acm_certificate_arn      = var.domain_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 503
    response_code         = 503
    response_page_path    = "/503.html"
    error_caching_min_ttl = 5
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["RU"]
    }
  }
}


resource "aws_cloudfront_cache_policy" "minimal_cache_policy" {
  name        = "MinimalCachePolicy"
  comment     = "Minimal cache policy for API Gateway"
  default_ttl = 0
  max_ttl     = 1
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "api_origin_request_policy" {
  name    = "APIGatewayOriginRequestPolicy"
  comment = "Origin request policy for API Gateway - forwarding all headers except Host"

  cookies_config {
    cookie_behavior = "all"
  }
  headers_config {
    header_behavior = "allExcept"
    headers {
      items = ["Host"]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}




resource "aws_cloudfront_function" "function" {
  name    = "${var.prefix}-www-redirects"
  comment = "Redirect to www.${var.domain_name}"
  runtime = "cloudfront-js-2.0"
  code    = file("${path.module}/redirect_function.js")
}

data "aws_route53_zone" "domain_zone" {
  name = var.domain_name
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_gateway" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

