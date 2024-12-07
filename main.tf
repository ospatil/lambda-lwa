terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2.7.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1" # Change this to your preferred region
}

// the following two may seem redundant, but following good practice to get the current region
data "aws_region" "current" {}

locals {
  region = "${data.aws_region.current.name}"
}

# Create a ZIP file from the source directory
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src/lambda/hono-app/dist/"
  output_path = "${path.module}/dist/lambda-hono-app.zip"
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "hono-lambda-web-adapter-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# Lambda function with Web Adapter Layer
resource "aws_lambda_function" "hono_lambda" {
  function_name = "hono-web-adapter-lambda"
  role          = aws_iam_role.lambda_role.arn

  # Use AWS managed Node.js runtime
  runtime = "nodejs22.x"

  # Set handler to run.sh as recommended by LWA
  handler = "run.sh"

  # Use the ZIP file of your compiled application
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Lambda Web Adapter Layer (arm64)
  layers = [
    "arn:aws:lambda:${local.region}:753240598075:layer:LambdaAdapterLayerArm64:23"
  ]

  # Lambda Web Adapter configuration
  environment {
    variables = {
      # LWA specific environment variable
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
      RUST_LOG = "info"
      # Optional: Customize port if your app uses a different one, 8080 is the default
      PORT = "8080"
    }
  }

  memory_size = 256
  timeout     = 10

  # Optional tags
  tags = {
    Environment = "Development"
    Project     = "HonoWebAdapter"
  }

  # Architectures (uncomment and adjust as needed)
  architectures = ["arm64"]  # Use this if you want ARM64
}

# API Gateway
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "hono-lambda-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.lambda_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.hono_lambda.invoke_arn
  integration_method = "POST" # has to be post for AWS_PROXY
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hono_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*/*"
}

# API Gateway stage
resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

# Output API Gateway endpoint
output "api_gateway_url" {
  value = aws_apigatewayv2_stage.lambda_stage.name == "$default" ? aws_apigatewayv2_stage.lambda_stage.invoke_url : "${aws_apigatewayv2_stage.lambda_stage.invoke_url}/"
}
