#terraform & aws version constraints and remote backend for state file 
terraform {
  required_version = "~> 1.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "my-terraform-backend-bucket123"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terraform-backend-locking-table"
  }
}


#AWS provider
provider "aws" {
  region  = var.aws_region
  profile = "default"
}
