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

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project}-${var.env}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.project}-${var.env}-lambda-logging-policy"
  description = "Allow Lambda functions to write logs to CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name = "${var.project}-${var.env}-lambda-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = var.db_secret_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

resource "aws_iam_policy" "lambda_vpc_permissions" {
  name        = "${var.project}-${var.env}-lambda-vpc-permissions"
  description = "Allow Lambda to manage ENIs in VPC"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_vpc_permissions.arn
}

resource "aws_iam_policy" "lambda_dynamodb_rw" {
  name        = "${var.project}-${var.env}-lambda-dynamodb-policy"
  description = "Allow Lambda to read/write to DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:DeleteItem"
      ],
      Resource = [
        var.dynamodb_health_table_arn,
        var.dynamodb_todo_table_arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_rw_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_rw.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SNS access policy for all Lambdas using this exec role
resource "aws_iam_policy" "lambda_sns_policy" {
  name        = "${var.project}-${var.env}-lambda-sns-policy"
  description = "Allow Lambdas to interact with SNS topics"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListTopics",
          "sns:ListSubscriptionsByTopic"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sns_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

# SQS access policy for all Lambdas using this exec role
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "${var.project}-${var.env}-lambda-sqs-policy"
  description = "Allow Lambdas to interact with SQS queues"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

# Allow all Lambdas using this role to query CloudWatch Logs
resource "aws_iam_policy" "lambda_logs_query_policy" {
  name        = "${var.project}-${var.env}-lambda-logs-query"
  description = "Allow all Lambdas to query CloudWatch Logs Insights"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:StartQuery",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs_query_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logs_query_policy.arn
}

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.project}-${var.env}-api"
  protocol_type = "HTTP"

  cors_configuration {
allow_origins = [
  "https://aws-serverless.net",
  "https://api.aws-serverless.net",
  "https://www.aws-serverless.net",
  "https://lingua1.com",
  "https://www.lingua1.com",
  "https://api.lingua1.com",
   "http://localhost"
]

    allow_methods  = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers  = ["Content-Type", "Authorization"]
    expose_headers = ["Content-Type"]
    
    allow_credentials = true
    max_age        = 3600
  }

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  name        = "dev"
  auto_deploy = false

  default_route_settings {
    throttling_burst_limit = 25
    throttling_rate_limit  = 50
  }
}


# 
# allow all lambdas S3 access here
#

resource "aws_iam_policy" "lambda_s3_rw" {
  name        = "${var.project}-${var.env}-lambda-s3-rw"
  description = "Allow Lambda to read and write objects in S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::t5-test-site",
          "arn:aws:s3:::t5-test-site/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_rw_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_rw.arn
}

