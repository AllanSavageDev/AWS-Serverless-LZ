output "lambda_function_name" {
  value = aws_lambda_function.t5_api_notify.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.t5_api_notify.arn
}

output "api_chart_integration_id" {
  value = aws_apigatewayv2_integration.t5_api_notify_integration.id
}

