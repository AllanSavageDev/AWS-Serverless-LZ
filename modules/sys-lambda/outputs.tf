output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "lambda_exec_role_name" {
  value = aws_iam_role.lambda_exec.name
}

output "api_gateway_id" {
  value = aws_apigatewayv2_api.api_gateway.id
}

output "api_gateway_execution_arn" {
  value = aws_apigatewayv2_api.api_gateway.execution_arn
}

output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.api_gateway.api_endpoint
}

output "stage_name" {
  value = aws_apigatewayv2_stage.default.name
}
