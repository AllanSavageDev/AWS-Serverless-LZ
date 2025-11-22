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
# LAMBDA: api-rds
#########################################################

resource "aws_lambda_function" "api_rds" {
  function_name    = "t5-api-rds"
  handler          = "lambda_handler.lambda_handler"
  runtime          = "python3.11"
  role             = var.lambda_exec_role_arn
  timeout          = 15
  filename         = "${path.module}/../../scripts/api-rds/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/../../scripts/api-rds/lambda_payload.zip")

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

resource "aws_apigatewayv2_integration" "api_rds" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api_rds.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Root CRUD routes
resource "aws_apigatewayv2_route" "api_rds_post" {
  api_id    = var.api_gateway_id
  route_key = "POST /api-rds"
  target    = "integrations/${aws_apigatewayv2_integration.api_rds.id}"
}

resource "aws_apigatewayv2_route" "api_rds_get" {
  api_id    = var.api_gateway_id
  route_key = "GET /api-rds"
  target    = "integrations/${aws_apigatewayv2_integration.api_rds.id}"
}


# ID-specific CRUD routes
resource "aws_apigatewayv2_route" "api_rds_get_by_id" {
  api_id    = var.api_gateway_id
  route_key = "GET /api-rds/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.api_rds.id}"
}

resource "aws_apigatewayv2_route" "api_rds_put" {
  api_id    = var.api_gateway_id
  route_key = "PUT /api-rds/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.api_rds.id}"
}

resource "aws_apigatewayv2_route" "api_rds_delete" {
  api_id    = var.api_gateway_id
  route_key = "DELETE /api-rds/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.api_rds.id}"
}

#########################################################
# PERMISSIONS
#########################################################

resource "aws_lambda_permission" "api_rds_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_rds.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
