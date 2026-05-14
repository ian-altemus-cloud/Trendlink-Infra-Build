output "vpc_id" {
  description = "ID of the dev spoke VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the dev spoke private subnets"
  value       = module.vpc.private_subnet_ids
}

output "private_route_table_ids" {
  description = "IDs of the dev spoke private route tables"
  value       = module.vpc.private_route_table_ids
}

output "dev_spoke_attachment_id" {
  description = "ID of the dev spoke TGW attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.dev_spoke.id
}