# -----------------------------------------------------------
# Lambda source zips
# -----------------------------------------------------------
data "archive_file" "ingestion_simulator" {
  type        = "zip"
  source_file = "${path.module}/../src/ingestion_simulator.py"
  output_path = "${path.module}/../src/ingestion_simulator.zip"
}

data "archive_file" "processor" {
  type        = "zip"
  source_file = "${path.module}/../src/processor.py"
  output_path = "${path.module}/../src/processor.zip"
}

# -----------------------------------------------------------
# Ingestion Simulator Lambda
# -----------------------------------------------------------
resource "aws_lambda_function" "ingestion_simulator" {
  function_name    = "${var.project}-${var.environment}-ingestion-simulator"
  role             = aws_iam_role.ingestion_simulator.arn
  handler          = "ingestion_simulator.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.ingestion_simulator.output_path
  source_code_hash = data.archive_file.ingestion_simulator.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      EVENT_BUS_NAME  = aws_cloudwatch_event_bus.pipeline.name
      ENVIRONMENT     = var.environment
    }
  }

    tags = {
    Name        = "${var.project}-${var.environment}-ingestion-simulator"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_lambda_function" "processor" {
  function_name    = "${var.project}-${var.environment}-processor"
  role             = aws_iam_role.processor.arn
  handler          = "processor.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.processor.output_path
  source_code_hash = data.archive_file.processor.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE   = aws_dynamodb_table.pipeline.name
      SNS_TOPIC_ARN    = aws_sns_topic.pipeline_alerts.arn
      PUSHGATEWAY_URL  = var.pushgateway_url
      ENVIRONMENT      = var.environment
    }
  }

  tags = {
    Name        = "${var.project}-${var.environment}-processor"
    Environment = var.environment
    Project     = var.project
  }
}

# -----------------------------------------------------------
# SQS trigger for processor Lambda
# -----------------------------------------------------------
resource "aws_lambda_event_source_mapping" "sqs_processor" {
  event_source_arn = aws_sqs_queue.pipeline.arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10
  enabled          = true
}