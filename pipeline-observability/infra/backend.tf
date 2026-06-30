terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

    backend "s3" {
    bucket         = "tl-tfstate-tv-027792787109"
    key            = "pipeline-observability/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tl-tfstate-tv-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}