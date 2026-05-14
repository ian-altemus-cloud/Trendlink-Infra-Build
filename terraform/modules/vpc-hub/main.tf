resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "tl-${var.environment}-nat"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}