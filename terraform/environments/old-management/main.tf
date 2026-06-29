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

data "aws_organizations_organization" "org" {}

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
  transit_gateway_id   = module.transit_gateway.transit_gateway_id
}

data "terraform_remote_state" "dev" {
  backend = "s3"
  config = {
    bucket = "tl-tfstate-dev-307217365914"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

module "transit_gateway" {
  source = "../../modules/transit-gateway"

  environment    = var.environment
  hub_vpc_id     = module.hub_vpc.vpc_id
  hub_subnet_ids = module.hub_vpc.private_subnet_ids
}

resource "aws_ram_resource_share" "tgw" {
  name                      = "tl-tgw-share"
  allow_external_principals = true

  tags = {
    Name        = "tl-tgw-share"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_ram_resource_association" "tgw" {
  resource_share_arn = aws_ram_resource_share.tgw.arn
  resource_arn       = module.transit_gateway.transit_gateway_arn
}

resource "aws_ram_principal_association" "dev" {
  principal          = "307217365914"
  resource_share_arn = aws_ram_resource_share.tgw.arn
}

module "security_groups_hub" {
  source = "../../modules/security-groups-hub"

  vpc_id            = module.hub_vpc.vpc_id
  environment       = var.environment
  project_name      = "tl"
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "bastion" {
  source = "../../modules/ec2"

  ami_id              = var.ami_id
  instance_type       = "t3.micro"
  subnet_id           = module.hub_vpc.public_subnet_ids[0]
  security_group_ids  = [module.security_groups_hub.bastion_sg_id]
  key_name            = "tl-bastion-kp"
  associate_public_ip = true
  environment         = var.environment
  project_name        = "tl"
  name                = "bastion"
  vpc_id              = module.hub_vpc.vpc_id
}

resource "aws_ec2_transit_gateway_route" "default_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.transit_gateway.hub_attachment_id
  transit_gateway_route_table_id = module.transit_gateway.tgw_route_table_id
}

resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name        = "tl-bastion-eip"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = module.bastion.instance_id
  allocation_id = aws_eip.bastion.id
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "github_actions_terraform" {
  name = "tl-github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:ian-altemus-cloud/Trendlink-Infra-Build:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "tl-github-actions-terraform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "tl-terraform-policy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "dev_tfstate_github" {
  bucket = "tl-tfstate-dev-307217365914"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::307217365914:role/tl-github-actions-terraform"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::tl-tfstate-dev-307217365914",
          "arn:aws:s3:::tl-tfstate-dev-307217365914/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "mgmt_tfstate_github" {
  bucket = "tl-tfstate-mgmt-387041334143"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.github_actions_terraform.arn,
            "arn:aws:iam::307217365914:role/tl-github-actions-terraform"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::tl-tfstate-mgmt-387041334143",
          "arn:aws:s3:::tl-tfstate-mgmt-387041334143/*"
        ]
      }
    ]
  })
}