output "static_site_cdn_domain" {
  description = "CloudFront domain for the static site"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "static_site_bucket" {
  value = aws_s3_bucket.site.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront domain for the static site"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "hosted_zone_id" {
  value = aws_cloudfront_distribution.site.hosted_zone_id
}
