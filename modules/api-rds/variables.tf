variable "region" {}

variable "project" {}

variable "env" {}
variable "tags" {type = map(string)}

variable "lambda_exec_role_arn" {}

variable "private_subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {}

variable "db_secret_arn" {}

variable "db_host" {}

variable "api_gateway_id" {}

variable "api_gateway_execution_arn" {}

