resource "aws_kms_key" "pipeline" {
  description             = "KMS key for pipeline observability - encrypts SQS and DynamoDB"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name        = "${var.project}-${var.environment}-kms"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_kms_alias" "pipeline" {
  name          = "alias/${var.project}-${var.environment}"
  target_key_id = aws_kms_key.pipeline.key_id
}