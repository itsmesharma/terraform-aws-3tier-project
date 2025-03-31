# Create the Internet Gateways
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform_igw"
  }
}

#create NAT gateways for private subnet
resource "aws_nat_gateway" "private_nat_gateway" {
  count         = length(aws_subnet.private_subnet) > 0 ? 2 : 0
  allocation_id = aws_eip.nat_gateway_eip.*.id[count.index]
  subnet_id     = element(aws_subnet.public_webtier_subnet.*.id, count.index)
  tags = {
    Name = "private-nat-gateway-${count.index}"
  }
  depends_on = [aws_internet_gateway.terraform_igw]
}

# Create an EIP for each NAT gateway
resource "aws_eip" "nat_gateway_eip" {
  count = length(aws_subnet.private_subnet) > 0 ? 2 : 0
  vpc   = true
  tags = {
    Name = "private-nat-gateway-${count.index}-eip"
  }
  depends_on = [aws_internet_gateway.terraform_igw]
}
