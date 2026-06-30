resource "aws_dynamodb_table" "pipeline" {
  name         = "${var.project}-${var.environment}-jobs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"
  range_key    = "timestamp"

  attribute {
    name = "job_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.pipeline.arn
  }

  tags = {
    Name        = "${var.project}-${var.environment}-jobs"
    Environment = var.environment
    Project     = var.project
  }
}