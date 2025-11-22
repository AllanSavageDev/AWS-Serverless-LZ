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

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  source_dest_check           = false

  tags = {
    Name    = "${var.project}-${var.env}-bastion"
    Project = var.project
    Env     = var.env
  }

  user_data = file("${path.module}/bastion_user_data_new.sh")
}

resource "aws_iam_role" "bastion_role" {
  name = "${var.project}-${var.env}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = var.project
    Env     = var.env
      Build   = "2" #bump to get a new user data to run
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# Numerious unnecessary permissions in here for the Demo work load
# This whole thing was adapted from other projects to work here
# The extra permissions aren't hurting anything 
# They are mostly centered around allowing the Bastion server configured in this project to do build related things
# Checking out Git code, calling Terraform, making new deployment resources etc
resource "aws_iam_role_policy" "bastion_fork_provision" {
  name   = "${var.project}-${var.env}-bastion-fork-provision"
  role   = aws_iam_role.bastion_role.id
  policy = file("${path.module}/policies/bastion_fork_provision.json")
}


resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.project}-${var.env}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}


# COMMENT THIS OUT FOR VPC ENDPOINT TESTING
# DO NOT DELETE THIS - YOU NEED IT
resource "aws_route" "private_to_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.bastion.primary_network_interface_id

  depends_on = [aws_instance.bastion]
}
