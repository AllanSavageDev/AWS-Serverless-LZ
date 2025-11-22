output "lambda_function_name" {
  value = aws_lambda_function.api_rds.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.api_rds.arn
}

output "api_rds_integration_id" {
  value = aws_apigatewayv2_integration.api_rds.id
}

