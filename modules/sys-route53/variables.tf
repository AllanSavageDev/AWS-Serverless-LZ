variable "region" {}

variable "project" {}

variable "env" {}

variable "tags" {type = map(string)}

variable "domain_name" {
  description = "Root domain name (e.g. aws-serverless.net)"
  type        = string
}

variable "cloudfront_domain" {
  description = "Domain name of CloudFront distribution (e.g. d123abc.cloudfront.net)"
  type        = string
}

variable "cloudfront_zone_id" {
  description = "Hosted zone ID of CloudFront distribution"
  type        = string
}

variable "all_domains" {
  type = map(string)
}