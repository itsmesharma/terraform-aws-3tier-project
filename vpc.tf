# Create VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block       = var.cidr_blocks[0]
  instance_tenancy = "default"
  tags = {
    Name = "Terraform_Demo_VPC"
  }
}

locals {
  az_names = ["us-east-1a", "us-east-1b"]
}

# Create 2 public subnets in two availability zones
resource "aws_subnet" "public_webtier_subnet" {
  count             = length(local.subnet_cidrs) > 0 ? 2 : 0
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = element(local.subnet_cidrs, count.index)
  availability_zone = element(local.az_names, count.index)
  # availability_zone       = "us-east-1${count.index + 1}"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Create 4 private subnets in two availability zones (2 each in 2 az's)
resource "aws_subnet" "private_subnet" {
  count  = length(local.subnet_cidrs) > 0 ? 4 : 0
  vpc_id = aws_vpc.terraform_vpc.id
  # cidr_block = element(local.subnet_cidrs, count.index % local.subnet_count)
  cidr_block = element(local.subnet_cidrs, count.index + 2)
  #cidr_block        = element(local.subnet_cidrs, count.index % length(local.subnet_cidrs))
  availability_zone = element(local.az_names, count.index % 2)
  # availability_zone = "us-east-1${count.index % 2 + 1}"
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}
