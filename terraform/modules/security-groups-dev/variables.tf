variable "vpc_id" {
  description = "ID of the VPC to create security groups in"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}