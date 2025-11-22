output "lambda_function_name" {
  value = aws_lambda_function.t5_api_todo.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.t5_api_todo.arn
}

output "api_chart_integration_id" {
  value = aws_apigatewayv2_integration.t5_api_todo_integration.id
}

