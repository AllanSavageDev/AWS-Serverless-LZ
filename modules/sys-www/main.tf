terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0"
    }
  }
  required_version = ">= 1.8.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}


locals {
  site_bucket_name = "${var.project}-${var.env}-site"

site_files = [
  for f in fileset("${path.root}/../../www", "**") :
  f if !startswith(f, "game/common/json/")
  ]

  mime_types = {
    html        = "text/html"
    css         = "text/css"
    js          = "application/javascript"
    json        = "application/json"
    png         = "image/png"
    jpg         = "image/jpeg"
    jpeg        = "image/jpeg"
    svg         = "image/svg+xml"
    ico         = "image/x-icon"
    txt         = "text/plain"
    map         = "application/json"
    webmanifest = "application/manifest+json"
    wasm        = "application/wasm"
  }
}

resource "aws_s3_bucket" "site" {
  bucket        = local.site_bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.site_bucket_name}-oac"
  description                       = "OAC for ${local.site_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "index_rewrite" {
  name    = "t5-index-rewrite"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite /path/ to /path/index.html"
  publish = true
  code    = file("${path.module}/rewrite.js")
}

resource "aws_s3_bucket" "cf_logs" {
  bucket = "${var.project}-${var.env}-cf-logs"
}

resource "aws_s3_bucket_ownership_controls" "cf_logs" {
  bucket = aws_s3_bucket.cf_logs.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_public_access_block" "cf_logs" {
  bucket                  = aws_s3_bucket.cf_logs.id
  block_public_acls       = false
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "cf_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cf_logs]
  bucket     = aws_s3_bucket.cf_logs.id
  acl        = "log-delivery-write"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_response_headers_policy" "allow_capacitor" {
  name = "AllowCapacitorCORS"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD"]
    }

    access_control_allow_origins {
      items = ["capacitor://localhost",
        "http://dev.lingua1.com:8080"]
    }

    origin_override = true
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.site_bucket_name} distribution"
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  tags                = var.tags

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

cache_policy_id           = data.aws_cloudfront_cache_policy.caching_optimized.id
origin_request_policy_id  = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id

    response_headers_policy_id  = aws_cloudfront_response_headers_policy.allow_capacitor.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.index_rewrite.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version        = "TLSv1.2_2021"
  }

  aliases = [
  "aws-serverless.net",
  "www.aws-serverless.net",
  "lingua1.com",
  "www.lingua1.com"
]

  logging_config {
    bucket = aws_s3_bucket.cf_logs.bucket_domain_name
    prefix = "cloudfront/"
    include_cookies = false
  }

  depends_on = [
    aws_s3_bucket_public_access_block.site,
    aws_s3_bucket_ownership_controls.site
  ]
}



data "aws_iam_policy_document" "site_policy" {
  statement {
    sid     = "AllowCloudFrontRead"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.site.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_policy.json
}

resource "aws_s3_object" "site_files" {
  for_each = { for f in local.site_files : f => f }

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${path.root}/../../www/${each.value}"
  etag   = filemd5("${path.root}/../../www/${each.value}")

  content_type = lookup(
    local.mime_types,
    regex("[^.]*$", each.value),
    "application/octet-stream"
  )

  depends_on = [
    aws_s3_bucket_ownership_controls.site,
    aws_s3_bucket_policy.site,
    aws_cloudfront_distribution.site
  ]
}

resource "null_resource" "invalidate_cf" {
  triggers = {
    site_etag = join(",", [for f in aws_s3_object.site_files : f.etag])
  }

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.site.id} --paths '/*'"
  }

  depends_on = [aws_s3_object.site_files]
}

resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = "api.aws-serverless.net"

  domain_name_configuration {
    certificate_arn = var.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = var.api_id
  domain_name = aws_apigatewayv2_domain_name.api_domain.domain_name
  stage       = "dev"
}

resource "aws_route53_record" "www_alias" {
  for_each = {
    "www.${var.domain_name}" = var.zone_id
    "www.lingua1.com"        = var.all_domains["lingua1.com"]
  }

  zone_id = each.value
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "api_alias" {
  for_each = {
    "api.${var.domain_name}" = var.zone_id
    "api.lingua1.com"        = var.all_domains["lingua1.com"]
  }

  zone_id = each.value
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_apigatewayv2_domain_name" "api_domain_lingua1" {
  domain_name = "api.lingua1.com"

  domain_name_configuration {
    certificate_arn = var.acm_certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping_lingua1" {
  api_id      = var.api_id
  domain_name = aws_apigatewayv2_domain_name.api_domain_lingua1.domain_name
  stage       = var.stage_name
}


