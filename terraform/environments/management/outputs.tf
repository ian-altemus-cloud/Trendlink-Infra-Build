output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.transit_gateway.transit_gateway_id
}

output "tgw_ram_share_arn" {
  description = "ARN of the TGW RAM resource share"
  value       = aws_ram_resource_share.tgw.arn
}