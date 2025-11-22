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

#########################################
# Lambda SG and Rules
#########################################

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project}-${var.env}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-lambda-sg"
  })
}

#########################################
# RDS SG and Rules
#########################################

resource "aws_security_group" "rds_sg" {
  name = "${var.project}-${var.env}-db-sg"
  description = "Allow Lambda & Bastion access to Postgres RDS"
  vpc_id      = var.vpc_id
  
  tags = merge(var.tags, {
    Name = "${var.project}-${var.env}-db-sg"
  })
}

resource "aws_security_group_rule" "allow_lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.rds_sg.id
  description              = "Allow Lambda to connect to RDS"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_sg.id
  description       = "Allow all outbound"
}

#########################################
# Bastion SG and Rules
#########################################

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project}-${var.env}-bastion-sg"
  description = "Security group for bastion host (SSM access only)"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all VPC traffic for NAT return path"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-bastion-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "allow_bastion_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.rds_sg.id
  description              = "Allow Bastion to connect to RDS"
}
