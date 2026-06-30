resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project}-${var.environment}-dlq"
  message_retention_seconds = 345600
  kms_master_key_id         = aws_kms_key.pipeline.key_id

  tags = {
    Name        = "${var.project}-${var.environment}-dlq"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_sqs_queue" "pipeline" {
  name                       = "${var.project}-${var.environment}-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
  kms_master_key_id          = aws_kms_key.pipeline.key_id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project}-${var.environment}-queue"
    Environment = var.environment
    Project     = var.project
  }
}
resource "aws_sqs_queue_policy" "pipeline" {
  queue_url = aws_sqs_queue.pipeline.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.pipeline.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.pipeline.arn
          }
        }
      }
    ]
  })
}