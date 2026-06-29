terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tl-tfstate-tv-027792787109"
    key            = "tv-dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tl-tfstate-tv-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/tv-vpc"

  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "eks" {
  source = "../../modules/eks"

  environment        = var.environment
  subnet_ids         = module.vpc.private_subnet_ids
  kubernetes_version = var.eks_kubernetes_version
  node_instance_type = var.eks_node_instance_type
  desired_nodes      = var.eks_desired_nodes
  min_nodes          = var.eks_min_nodes
  max_nodes          = var.eks_max_nodes
}

resource "aws_ecr_repository" "app" {
  name                 = "trendview-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "trendview-app"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "tl-tfstate-tv-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "tl-tfstate-tv-lock"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}