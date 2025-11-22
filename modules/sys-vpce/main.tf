terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

output "module_path" {
  value = path.module
}


#########################################################
# VPC Endpoint DynamoDB # Note this is a Gateway endpoint and these do not have security group associations
#########################################################
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.private_route_table_id]
  tags              = var.tags
}

#########################################################
# VPC Endpoint (SQS)
#########################################################

resource "aws_vpc_endpoint" "vpce_sqs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce_sqs.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-sqs"
  })
}

#########################################################
# SECURITY GROUP for VPC Endpoint (SQS)
#########################################################

resource "aws_security_group" "vpce_sqs" {
  name        = "${var.project}-${var.env}-vpce-sqs-sg"
  description = "Allow HTTPS from Lambda to SQS VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id] # allow from your Lambda SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-sqs-sg"
  })
}

#########################################################
# VPC Endpoint (SNS)
#########################################################

resource "aws_vpc_endpoint" "vpce_sns" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.sns"
  vpc_endpoint_type   = "Interface"
  subnet_ids          =var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce_sns.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-sns"
  })
}

resource "aws_security_group" "vpce_sns" {
  name        = "${var.project}-${var.env}-vpce-sns-sg"
  description = "Allow HTTPS from Lambda to SNS VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-sns-sg"
  })
}

#########################################################
# VPC Endpoint (CloudWatch)
#########################################################

resource "aws_vpc_endpoint" "vpce_cloudwatch" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          =var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce_cloudwatch.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-cloudwatch"
  })
}

resource "aws_security_group" "vpce_cloudwatch" {
  name        = "${var.project}-${var.env}-vpce-cloudwatch-sg"
  description = "Allow HTTPS from Lambda to CloudWatch VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTPS from Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-sns-sg"
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce_secrets_sg.id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-secrets"
  })
}
resource "aws_security_group" "vpce_secrets_sg" {
  name        = "${var.project}-${var.env}-vpce-secrets-sg"
  description = "Allow Lambda access to Secrets Manager"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id]         # allow inbound from Lambda SG
    description     = "Allow HTTPS from Lambda"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-vpce-secrets-sg"
  })
}


