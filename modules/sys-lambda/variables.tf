variable "region" {}

variable "project" {}

variable "env" {}

variable "tags" {type = map(string)}

variable "vpc_id" {}

variable "db_secret_arn" {}

variable "dynamodb_health_table_arn" {
  type        = string
  description = "ARN of the health DynamoDB table"
}

variable "dynamodb_todo_table_arn" {
  type        = string
  description = "ARN of the todo DynamoDB table"
}

