variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "tv-dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}


variable "availability_zones" {
  description = "Availability zones to deploy into"
  type        = list(string)
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
}


variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
}

variable "eks_desired_nodes" {
  description = "Desired number of EKS worker nodes"
  type        = number
}

variable "eks_min_nodes" {
  description = "Minimum number of EKS worker nodes"
  type        = number
}

variable "eks_max_nodes" {
  description = "Maximum number of EKS worker nodes"
  type        = number
}
