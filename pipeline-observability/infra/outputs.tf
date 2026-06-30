output "sqs_queue_url" {
  description = "Pipeline SQS queue URL"
  value       = aws_sqs_queue.pipeline.url
}

output "sqs_queue_arn" {
  description = "Pipeline SQS queue ARN"
  value       = aws_sqs_queue.pipeline.arn
}

output "dlq_url" {
  description = "Dead letter queue URL"
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "Dead letter queue ARN"
  value       = aws_sqs_queue.dlq.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB jobs table name"
  value       = aws_dynamodb_table.pipeline.name
}
output "dynamodb_table_arn" {
  description = "DynamoDB jobs table ARN"
  value       = aws_dynamodb_table.pipeline.arn
}

output "sns_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = aws_sns_topic.pipeline_alerts.arn
}

output "event_bus_name" {
  description = "EventBridge custom bus name"
  value       = aws_cloudwatch_event_bus.pipeline.name
}

output "event_bus_arn" {
  description = "EventBridge custom bus ARN"
  value       = aws_cloudwatch_event_bus.pipeline.arn
}

output "ingestion_simulator_function_name" {
  description = "Ingestion simulator Lambda function name"
  value       = aws_lambda_function.ingestion_simulator.function_name
}


output "processor_function_name" {
  description = "Processor Lambda function name"
  value       = aws_lambda_function.processor.function_name
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = aws_kms_key.pipeline.arn
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.pipeline.name
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.pipeline.dashboard_name}"

output "pushgateway_url" {
  description = "Prometheus Pushgateway endpoint"
  value       = var.pushgateway_url
}