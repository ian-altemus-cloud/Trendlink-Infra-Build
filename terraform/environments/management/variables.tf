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

variable "hub_vpc_cidr" {
  description = "CIDR block for the hub VPC"
  type        = string
}

variable "hub_public_subnet_cidrs" {
  description = "CIDR blocks for hub public subnets"
  type        = list(string)
}

variable "hub_private_subnet_cidrs" {
  description = "CIDR blocks for hub private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones to deploy into"
  type        = list(string)
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into the bastion"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}