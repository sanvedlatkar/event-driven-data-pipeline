############################################
# Terraform Configuration + Remote State
############################################

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "sanved-eventpipeline-dev-raw-data"
    key     = "terraform/state.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################################
# Provider
############################################

provider "aws" {
  region = "ap-south-1"
}

############################################
# S3 Buckets
############################################

resource "aws_s3_bucket" "raw_data" {
  bucket = "sanved-eventpipeline-dev-raw-data"
}

resource "aws_s3_bucket_versioning" "raw_data_versioning" {
  bucket = aws_s3_bucket.raw_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "reports" {
  bucket = "sanved-eventpipeline-dev-reports"
}

############################################
# IAM Role for Lambda
############################################

resource "aws_iam_role" "lambda_role" {
  name = "sanved-eventpipeline-dev-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

############################################
# IAM Policies
############################################

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 Access Policy
resource "aws_iam_policy" "lambda_s3_access" {
  name = "sanved-eventpipeline-dev-lambda-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.raw_data.arn
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = [
          "${aws_s3_bucket.raw_data.arn}/*",
          "${aws_s3_bucket.reports.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_access.arn
}

############################################
# Lambda: Ingest
############################################

resource "aws_lambda_function" "ingest_lambda" {
  function_name = "sanved-eventpipeline-dev-ingest-lambda"
  runtime       = "python3.10"
  handler       = "ingest.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.module}/../lambda/ingest.zip"
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      RAW_DATA_BUCKET = aws_s3_bucket.raw_data.bucket
    }
  }
}

############################################
# Lambda: Process
############################################

resource "aws_lambda_function" "process_lambda" {
  function_name = "sanved-eventpipeline-dev-process-lambda"
  runtime       = "python3.10"
  handler       = "process.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.module}/../lambda/process.zip"
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      RAW_DATA_BUCKET = aws_s3_bucket.raw_data.bucket
    }
  }
}

############################################
# Lambda: Report
############################################

resource "aws_lambda_function" "report_lambda" {
  function_name = "sanved-eventpipeline-dev-report-lambda"
  runtime       = "python3.10"
  handler       = "report.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.module}/../lambda/report.zip"
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      RAW_DATA_BUCKET = aws_s3_bucket.raw_data.bucket
      REPORTS_BUCKET  = aws_s3_bucket.reports.bucket
    }
  }
}

############################################
# EventBridge (Daily Report Trigger)
############################################

resource "aws_cloudwatch_event_rule" "daily_report_schedule" {
  name                = "sanved-eventpipeline-dev-daily-report"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "daily_report_target" {
  rule = aws_cloudwatch_event_rule.daily_report_schedule.name
  arn  = aws_lambda_function.report_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge_report" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report_schedule.arn
}
