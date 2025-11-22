terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0"
    }
  }
  required_version = ">= 1.8.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

#########################################################
# LAMBDA: api-todo
#########################################################

resource "aws_lambda_function" "t5_api_todo" {
  function_name    = "t5-api-todo"
  handler          = "lambda_handler.lambda_handler"
  runtime          = "python3.11"
  role             = var.lambda_exec_role_arn
  timeout          = 15
  filename         = "${path.module}/../../scripts/api-todo/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/../../scripts/api-todo/lambda_payload.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      SECRET_ARN = var.db_secret_arn
      DB_HOST    = var.db_host
      TABLE_NAME = "${var.project}-${var.env}-todo-table"
    }
  }
}

#########################################################
# API GATEWAY ROUTING
#########################################################

resource "aws_apigatewayv2_integration" "t5_api_todo_integration" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.t5_api_todo.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Root CRUD routes
resource "aws_apigatewayv2_route" "api_todo_post" {
  api_id    = var.api_gateway_id
  route_key = "POST /api-todo"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_todo_integration.id}"
}

resource "aws_apigatewayv2_route" "api_todo_get" {
  api_id    = var.api_gateway_id
  route_key = "GET /api-todo"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_todo_integration.id}"
}

resource "aws_apigatewayv2_route" "api_todo_put_root" {
  api_id    = var.api_gateway_id
  route_key = "PUT /api-todo"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_todo_integration.id}"
}

resource "aws_apigatewayv2_route" "api_todo_delete" {
  api_id    = var.api_gateway_id
  route_key = "DELETE /api-todo/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_todo_integration.id}"
}

# Explicit CORS preflight routes
resource "aws_apigatewayv2_route" "cors_api_todo_root" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /api-todo"
}

resource "aws_apigatewayv2_route" "cors_api_todo_id" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /api-todo/{id}"
}

#########################################################
# PERMISSIONS
#########################################################

resource "aws_lambda_permission" "t5_api_todo_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.t5_api_todo.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
