terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tl-tfstate-dev-307217365914"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tl-tfstate-dev-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  profile = "tl-mgmt"

  assume_role {
    role_arn = "arn:aws:iam::307217365914:role/OrganizationAccountAccessRole"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}