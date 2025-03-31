variable "aws_region" {
  default = "us-east-1"
  type    = string
}

# Define CIDR blocks for VPC and subnets
variable "cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/16", "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24"]
}

# Set variables for VPC and subnets
locals {
  vpc_cidr     = var.cidr_blocks[0]
  subnet_cidrs = slice(var.cidr_blocks, 1, length(var.cidr_blocks) - 1)
  subnet_count = length(local.subnet_cidrs)
}
