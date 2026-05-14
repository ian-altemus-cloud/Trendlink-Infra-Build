variable "environment" {
  description = "Environment name used for resource naming and tagging"
  type        = string
}

variable "hub_vpc_id" {
  description = "Identifier of the VPC for the hub VPC"
  type        = string
}

variable "hub_subnet_ids" {
  description = "Identifier of the hub subnets"
  type        = list(string)
}
