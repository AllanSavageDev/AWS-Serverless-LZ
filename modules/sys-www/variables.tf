variable "region" {}

variable "project" {}

variable "env" {}

variable "tags" {}

variable "api_base_url" {
  description = "Base URL of your API Gateway stage"
  type        = string
}

variable "api_id" {
  description = "ID of the API Gateway HTTP API"
  type        = string
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
}

variable "domain_name" {
  type        = string
  description = "Root domain for CloudFront (e.g. aws-serverless.net)"
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for CloudFront"
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID for aws-serverless.net"
  type        = string
}

variable "all_domains" {
  type = map(string)
}
