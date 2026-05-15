resource "aws_ec2_transit_gateway" "main" {
  description = "TrendLink Transit Gateway"
  auto_accept_shared_attachments  = "enable"

  tags = {
    Name        = "tl-${var.environment}-tgw"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.hub_vpc_id
  subnet_ids         = var.hub_subnet_ids

  tags = {
    Name        = "tl-${var.environment}-tgw-hub-attachment"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
