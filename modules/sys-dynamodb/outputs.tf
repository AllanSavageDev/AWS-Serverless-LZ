output "health_table_name" {
  description = "Name of the DynamoDB health table"
  value       = aws_dynamodb_table.health.name
}

output "health_table_arn" {
  description = "ARN of the DynamoDB health table"
  value       = aws_dynamodb_table.health.arn
}

output "todo_table_arn" {
  value = aws_dynamodb_table.todo.arn
}
