# 
# Terraform basic setup 
#
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

# 
# This is the main module Terraofrm file
# This is a set of calls to submodules that define specific behavoir
# In the scope of this project, I choose to define AWS System Resources in modules named sys-*
# I choose to name API related modules (modules that make a Lambda API run at a given URL) as api-*
# Be aware of this convention as you scan this file
# 

# 
# Resources realted to VPC configuration, subnets, CIDR ranges etc
#
module "sys_vpc" {
  source  = "../../modules/sys-vpc"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  vpc_cidr = var.vpc_cidr
}

# 
# VPC Endpoints allowing AWS Network private access from private subnet resources to AWS managed services (S3, Dynamo, etc)
#
module "sys_vpce" {
  source  = "../../modules/sys-vpce"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  vpc_id                 = module.sys_vpc.vpc_id
  lambda_sg_id           = module.sys_security.lambda_sg_id
  private_subnet_ids     = module.sys_vpc.private_subnet_ids
  private_route_table_id = module.sys_vpc.private_route_table_id
}

# 
# Necessary security groups 
#
module "sys_security" {
  source  = "../../modules/sys-security"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  vpc_id = module.sys_vpc.vpc_id
}


# 
# If you're running from a public subnet, you have a public IP and life is easy
# If you're running from a private subnet you do not have outside internet access
# This bastion server does double duty in the VPC configuration 
# It provides both outside Internet access for the stack via NAT GW emulation ( for free more or less )
# as well as allowin remote DB connections via a tunnel
#
module "sys_bastion" {
  source  = "../../modules/sys-bastion"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  bastion_sg_id          = module.sys_security.bastion_sg_id
  instance_type          = var.instance_type
  private_route_table_id = module.sys_vpc.private_route_table_id
  public_subnet_id       = module.sys_vpc.public_subnet_ids[0]
  vpc_id                 = module.sys_vpc.vpc_id
}

data "aws_route53_zone" "main" {
  name         = "aws-serverless.net"
  private_zone = false
}

data "aws_route53_zone" "lingua1" {
  name         = "lingua1.com"
  private_zone = false
}

# 
# Configs related to domain names and DNS
#
module "sys_route53" {
  source  = "../../modules/sys-route53"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  cloudfront_domain  = module.sys_www.cloudfront_domain_name
  cloudfront_zone_id = module.sys_www.hosted_zone_id
  domain_name        = "aws-serverless.net"

  all_domains = {
    "aws-serverless.net"     = data.aws_route53_zone.main.zone_id
    "www.aws-serverless.net" = data.aws_route53_zone.main.zone_id
    "api.aws-serverless.net" = data.aws_route53_zone.main.zone_id
    "lingua1.com"            = data.aws_route53_zone.lingua1.zone_id
    "www.lingua1.com"        = data.aws_route53_zone.lingua1.zone_id
    "api.lingua1.com"        = data.aws_route53_zone.lingua1.zone_id
  }
}

# 
# RDS Postgres is setup here
#
module "sys_rds" {
  source  = "../../modules/sys-rds"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  db_password        = var.db_password
  db_username        = var.db_username
  private_subnet_ids = module.sys_vpc.private_subnet_ids
  rds_sg_id          = module.sys_security.rds_sg_id
}

# 
# Dynamo is setup here
#
module "sys_dynamodb" {
  source  = "../../modules/sys-dynamodb"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags
}

# 
# Lambda is setup here
#
module "sys_lambda" {
  source  = "../../modules/sys-lambda"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  db_secret_arn             = module.sys_rds.db_secret_arn
  dynamodb_health_table_arn = module.sys_dynamodb.health_table_arn
  dynamodb_todo_table_arn   = module.sys_dynamodb.todo_table_arn
  vpc_id                    = module.sys_vpc.vpc_id
}

# 
# Cloudfront
#
module "sys_www" {
  source  = "../../modules/sys-www"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  acm_certificate_arn = module.sys_route53.certificate_arn
  api_base_url = module.sys_lambda.api_gateway_endpoint
  api_id       = module.sys_lambda.api_gateway_id
  stage_name   = module.sys_lambda.stage_name

  domain_name = "aws-serverless.net" # put this in variables

  all_domains = {
    "aws-serverless.net"     = data.aws_route53_zone.main.zone_id
    "www.aws-serverless.net" = data.aws_route53_zone.main.zone_id
    "api.aws-serverless.net" = data.aws_route53_zone.main.zone_id
    "lingua1.com"            = data.aws_route53_zone.lingua1.zone_id
    "www.lingua1.com"        = data.aws_route53_zone.lingua1.zone_id
    "api.lingua1.com"        = data.aws_route53_zone.lingua1.zone_id
  }

  zone_id = module.sys_route53.zone_id
}



#
# Below this marker, we're still defining moduldes but we move from sys-* modules above to api-* modules below
# All of these are basically function calls to Terraform "modules" where a specific configuration is handled
# Below we're defining user code behavoir such as specific APIs
# In general, system configs are in sys-* and user things may be api-* for APIs
# You might have lambdas responding to S3 or Event Bridge calls - in which case you might name those job-* 
# This is just an application layer separation below
# 
# Note that while it seems repetitive, each service is in fact somewhat repetitive
# Any service/Lambda defined here will need Database, Dynamo and to know what API GW invokes it and what not
# Its necesary to pass those things from the central "main" location into the "module" like this
#

module "api_rds" {
  source  = "../../modules/api-rds"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_quiz" {
  source  = "../../modules/api-quiz"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_game" {
  source  = "../../modules/api-game"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_log" {
  source  = "../../modules/api-log"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_notify" {
  source  = "../../modules/api-notify"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_queue" {
  source  = "../../modules/api-queue"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_todo" {
  source  = "../../modules/api-todo"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}

module "api_weather" {
  source  = "../../modules/api-weather"
  region  = var.region
  project = var.project
  env     = var.env
  tags    = var.tags

  private_subnet_ids = module.sys_vpc.private_subnet_ids
  lambda_sg_id       = module.sys_security.lambda_sg_id

  lambda_exec_role_arn = module.sys_lambda.lambda_exec_role_arn

  db_secret_arn = module.sys_rds.db_secret_arn
  db_host       = module.sys_rds.db_host

  api_gateway_id            = module.sys_lambda.api_gateway_id
  api_gateway_execution_arn = module.sys_lambda.api_gateway_execution_arn
}
