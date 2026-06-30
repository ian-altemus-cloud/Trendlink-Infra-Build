resource "aws_cloudwatch_event_bus" "pipeline" {
  name = "${var.project}-${var.environment}-bus"

  tags = {
    Name        = "${var.project}-${var.environment}-bus"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_event_rule" "pipeline" {
  name           = "${var.project}-${var.environment}-rule"
  description    = "Capture pipeline ingestion job started events"
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name

  event_pattern = jsonencode({
    source      = ["pipeline.ingestion"]
    detail-type = ["JobStarted"]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-rule"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule           = aws_cloudwatch_event_rule.pipeline.name
  event_bus_name = aws_cloudwatch_event_bus.pipeline.name
  target_id      = "SendToSQS"
  arn            = aws_sqs_queue.pipeline.arn
}