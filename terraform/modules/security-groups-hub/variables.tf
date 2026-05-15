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

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion host"
  type        = list(string)
}