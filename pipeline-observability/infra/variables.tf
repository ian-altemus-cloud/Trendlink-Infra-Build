variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "pipeline-observability"
}

variable "sns_alert_email" {
  description = "Email address for pipeline failure alerts"
  type        = string
  default     = "ianaltemustech@gmail.com"
}

variable "pushgateway_url" {
  description = "Prometheus Pushgateway endpoint"
  type        = string
  default     = "http://ae6e03c0c287c4c77a21071666a18b18-2017249357.us-east-1.elb.amazonaws.com:9091"
}