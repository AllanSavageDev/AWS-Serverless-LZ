variable "region" {}

variable "project" {}

variable "env" {}

variable "tags" {type = map(string)}

variable "vpc_id" {}

variable "instance_type" {}

variable "public_subnet_id" {}

variable "private_route_table_id" {}

variable "bastion_sg_id" {}

