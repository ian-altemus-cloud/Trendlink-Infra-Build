resource "aws_security_group" "dev_compute" {
  name        = "${var.project_name}-${var.environment}-dev-compute-sg"
  description = "Security group for dev env ec2 compute"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "inbound SSH from bastion host only"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "outbound to internet"
  }

    egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "outbound to DNS resolver"
  }
  tags = {
    Name        = "${var.project_name}-${var.environment}-dev-compute-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}