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

resource "aws_kms_key" "pipeline" {
  description             = "KMS key for pipeline observability - encrypts SQS and DynamoDB"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::027792787109:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EventBridge to use the key"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SNS to use the key"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })

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