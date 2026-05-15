output "dev_compute_sg_id" {
  description = "ID of the dev compute security group"
  value       = aws_security_group.dev_compute.id
}