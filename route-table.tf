
# Create a route tables for the public subnets
resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }
  count = length(aws_subnet.public_webtier_subnet) > 0 ? 2 : 0
  tags = {
    Name = "public-subnet-route-table-${count.index}"
  }
}

# Create a route tables for the private subnets
resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id
  count  = length(aws_subnet.private_subnet) > 0 ? 2 : 0
  tags = {
    Name = "private-subnet-route-table-${count.index}"
  }
}

# Associate public subnets with public route tables
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(aws_subnet.public_webtier_subnet) > 0 ? 2 : 0
  subnet_id      = element(aws_subnet.public_webtier_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.public_subnet_route_table.*.id, count.index)
  depends_on     = [aws_internet_gateway.terraform_igw]
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.private_subnet) > 0 ? 4 : 0
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index % length(aws_subnet.private_subnet))
  route_table_id = element(aws_route_table.private_subnet_route_table.*.id, count.index % length(aws_route_table.private_subnet_route_table))
  depends_on     = [aws_internet_gateway.terraform_igw]
}


