resource "aws_sns_topic" "pipeline_alerts" {
  name              = "${var.project}-${var.environment}-alerts"
  kms_master_key_id = aws_kms_key.pipeline.key_id

  tags = {
    Name        = "${var.project}-${var.environment}-alerts"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_sns_topic_subscription" "pipeline_alerts_email" {
  topic_arn = aws_sns_topic.pipeline_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_alert_email
}