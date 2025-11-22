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
# LAMBDA: api-queue
#########################################################

resource "aws_lambda_function" "t5_api_queue" {
  function_name    = "t5-api-queue"
  handler          = "lambda_handler.lambda_handler"
  runtime          = "python3.11"
  role             = var.lambda_exec_role_arn
  timeout          = 15
  filename         = "${path.module}/../../scripts/api-queue/lambda_payload.zip"
  source_code_hash = filebase64sha256("${path.module}/../../scripts/api-queue/lambda_payload.zip")

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      SECRET_ARN = var.db_secret_arn
      DB_HOST    = var.db_host
      TABLE_NAME = "${var.project}-${var.env}-todo-table"
      QUEUE_URL = aws_sqs_queue.queue.url
    }
  }
}

#########################################################
# API GATEWAY ROUTING
#########################################################

resource "aws_apigatewayv2_integration" "t5_api_queue_integration" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.t5_api_queue.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Root routes
resource "aws_apigatewayv2_route" "api_queue_post" {
  api_id    = var.api_gateway_id
  route_key = "POST /api-queue"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_queue_integration.id}"
}

resource "aws_apigatewayv2_route" "api_queue_get" {
  api_id    = var.api_gateway_id
  route_key = "GET /api-queue"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_queue_integration.id}"
}

resource "aws_apigatewayv2_route" "api_queue_put" {
  api_id    = var.api_gateway_id
  route_key = "PUT /api-queue"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_queue_integration.id}"
}

resource "aws_apigatewayv2_route" "api_queue_delete" {
  api_id    = var.api_gateway_id
  route_key = "DELETE /api-queue"
  target    = "integrations/${aws_apigatewayv2_integration.t5_api_queue_integration.id}"
}

# CORS preflight
resource "aws_apigatewayv2_route" "cors_api_queue" {
  api_id    = var.api_gateway_id
  route_key = "OPTIONS /api-queue"
}


#########################################################
# PERMISSIONS
#########################################################

resource "aws_lambda_permission" "t5_api_queue_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.t5_api_queue.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# SQS Queue
resource "aws_sqs_queue" "queue" {
  name = "${var.project}-${var.env}-queue"
}
