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

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = "${var.project}-${var.env}-vpc"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.project}-${var.env}-public-${count.index}"
    Tier = "public"
  }, var.tags)
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone = local.azs[count.index]

  tags = merge({
    Name = "${var.project}-${var.env}-private-${count.index}"
    Tier = "private"
  }, var.tags)
}

resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.this.id
  tags = merge({
    Name = "${var.project}-${var.env}-igw"
  }, var.tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_igw.id
  }

  tags = merge({
    Name = "${var.project}-${var.env}-public-rt"
  }, var.tags)

  depends_on = [aws_internet_gateway.aws_igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "${var.project}-${var.env}-private-rt"
  }, var.tags)
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

