output "lambda_function_name" {
  value = aws_lambda_function.api_weather.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.api_weather.arn
}

output "api_health_integration_id" {
  value = aws_apigatewayv2_integration.api_weather.id
}
