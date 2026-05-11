variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account ID for the management account"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "management"
}