terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "tl-tfstate-mgmt-387041334143"
    key            = "management/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tl-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "dev"
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::307217365914:role/OrganizationAccountAccessRole"
  }
}

resource "aws_organizations_organization" "tl_org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com"
  ]

  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.tl_org.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.tl_org.roots[0].id
}

resource "aws_organizations_account" "dev" {
  name      = "tl-dev"
  email     = "silverlinkinc+tl-dev@outlook.com"
  parent_id = aws_organizations_organizational_unit.workloads.id

  role_name = "OrganizationAccountAccessRole"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

module "hub_vpc" {
  source = "../../modules/vpc-hub"

  vpc_cidr             = var.hub_vpc_cidr
  environment          = "hub"
  public_subnet_cidrs  = var.hub_public_subnet_cidrs
  private_subnet_cidrs = var.hub_private_subnet_cidrs
  availability_zones   = var.availability_zones
}