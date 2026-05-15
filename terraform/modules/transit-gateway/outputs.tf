output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "hub_attachment_id" {
  description = "ID of the hub VPC attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}