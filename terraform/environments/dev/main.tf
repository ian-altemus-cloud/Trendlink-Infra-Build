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
  region  = var.aws_region
  profile = "tl-mgmt"

  assume_role {
    role_arn = "arn:aws:iam::307217365914:role/OrganizationAccountAccessRole"
  }
}

module "vpc" {
  source = "../../modules/dev-vpc-spoke"

  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

data "terraform_remote_state" "management" {
  backend = "s3"
  config = {
    bucket = "tl-tfstate-mgmt-387041334143"
    key    = "management/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_spoke" {
  transit_gateway_id = data.terraform_remote_state.management.outputs.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  tags = {
    Name        = "tl-dev-tgw-spoke-attachment"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_route" "to_tgw" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = data.terraform_remote_state.management.outputs.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.dev_spoke]
}