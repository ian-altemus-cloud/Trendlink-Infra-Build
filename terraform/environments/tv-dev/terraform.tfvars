aws_region           = "us-east-1"
environment          = "tv-dev"
vpc_cidr             = "10.2.0.0/16"
private_subnet_cidrs = ["10.2.3.0/24", "10.2.4.0/24"]
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

eks_kubernetes_version = "1.31"
eks_node_instance_type = "t3.medium"
eks_desired_nodes      = 2
eks_min_nodes          = 1
eks_max_nodes          = 3# trigger
