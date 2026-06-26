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

module "security_groups_dev" {
  source = "../../modules/security-groups-dev"

  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = "tl"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "dev_spoke" {
  transit_gateway_id = data.terraform_remote_state.management.outputs.transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  depends_on = [module.vpc]

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

output "tgw_id_from_state" {
  value = data.terraform_remote_state.management.outputs.transit_gateway_id
}

module "minikube" {
  source = "../../modules/ec2"

  ami_id              = var.ami_id
  instance_type       = "t3.large"
  subnet_id           = module.vpc.private_subnet_ids[0]
  security_group_ids  = [module.security_groups_dev.dev_compute_sg_id]
  key_name            = "tl-dev-kp"
  associate_public_ip = false
  environment         = var.environment
  project_name        = "tl"
  name                = "minikube"
  vpc_id              = module.vpc.vpc_id
}

resource "aws_ecr_repository" "app" {
  name                 = "trendlink-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "trendlink-app"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
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

resource "aws_iam_role" "github_actions_ecr" {
  name = "tl-github-actions-ecr"

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
            "token.actions.githubusercontent.com:sub" = "repo:ian-altemus-cloud/trendlink-app:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "tl-github-actions-ecr"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "tl-ecr-push-policy"
  role = aws_iam_role.github_actions_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
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

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "tl-tfstate-dev-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "tl-tfstate-dev-lock"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
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