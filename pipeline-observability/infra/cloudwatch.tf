resource "aws_cloudwatch_dashboard" "pipeline" {
  dashboard_name = "${var.project}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Pipeline Throughput - Jobs Processed Per Hour"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project}-${var.environment}-processor", { stat = "Sum", period = 3600 }]
          ]
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Failure Rate - DLQ Message Count"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", "${var.project}-${var.environment}-dlq", { stat = "Sum", period = 3600, color = "#d13212" }]
          ]
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Queue Depth - Messages Visible"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "${var.project}-${var.environment}-queue", { stat = "Maximum", period = 300 }]
          ]
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Processing Latency - Lambda Duration"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project}-${var.environment}-processor", { stat = "Average", period = 300 }]
          ]
          region = var.aws_region
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ingestion_simulator" {
  name              = "/aws/lambda/${var.project}-${var.environment}-ingestion-simulator"
  retention_in_days = 14

  tags = {
    Name        = "${var.project}-${var.environment}-ingestion-simulator-logs"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${var.project}-${var.environment}-processor"
  retention_in_days = 14

  tags = {
    Name        = "${var.project}-${var.environment}-processor-logs"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  alarm_name          = "${var.project}-${var.environment}-dlq-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Messages in DLQ indicate failed pipeline jobs - potential compliance event"
  alarm_actions       = [aws_sns_topic.pipeline_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  tags = {
    Name        = "${var.project}-${var.environment}-dlq-alarm"
    Environment = var.environment
    Project     = var.project
  }
}