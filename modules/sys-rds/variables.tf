variable "region" {}

variable "project" {}

variable "env" {}

variable "tags" {type = map(string)}

variable "db_username" {}

variable "db_password" {}

variable "rds_sg_id" {}

variable "private_subnet_ids" {
  type = list(string)
}
