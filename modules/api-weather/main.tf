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
# LAMBDA: api-weather
#########################################################

resource "aws_lambda_function" "api_weather" {
  function_name    = "t5-api-weather"
  handler          = "lambda_handler.lambda_handler"
  runtime          = "python3.11"
  role             = var.lambda_exec_role_arn
  timeout          = 15
  filename         = "${path.module}/../../scripts/api-weather/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/../../scripts/api-weather/lambda_payload.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      SECRET_ARN = var.db_secret_arn
      DB_HOST    = var.db_host
      TABLE_NAME = "${var.project}-${var.env}-health"
    }
  }
}

#########################################################
# API GATEWAY ROUTING
#########################################################

resource "aws_apigatewayv2_integration" "api_weather" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_weather.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "api_weather" {
  api_id    = var.api_gateway_id
  route_key = "ANY /api-weather"
  target    = "integrations/${aws_apigatewayv2_integration.api_weather.id}"
}

#########################################################
# PERMISSIONS
#########################################################

resource "aws_lambda_permission" "api_weather_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_weather.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
