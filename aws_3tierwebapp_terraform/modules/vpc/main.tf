# Define the VPC 
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}_igw"
  }
}

# Use data source to get all avalablility zones in region
data "aws_availability_zones" "available" {}

# We only use the first 2 AZs
locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "private_subnet_${local.availability_zones[count.index]}"
  }
}

# Deploy the private subnets for the DB
resource "aws_subnet" "private_subnets_db" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "private_subnet_db_${local.availability_zones[count.index]}"
  }
}

# Deploy the private subnets
resource "aws_subnet" "public_subnets" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_${local.availability_zones[count.index]}"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  count      = length(aws_subnet.public_subnets)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "nat_gateway_eip_${count.index + 1}"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  count         = length(aws_eip.nat_gateway_eip)
  depends_on    = [aws_subnet.public_subnets]
  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = "nat_gateway_${local.availability_zones[count.index]}"
  }
}

# Create route tables for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "public_rtb"
  }
}

# Create route tables for private subnets
resource "aws_route_table" "private_route_table" {
  count  = length(aws_subnet.private_subnets)
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }
  tags = {
    Name = "private_rtb_${local.availability_zones[count.index]}"
  }
}

# Create route table associations
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table[count.index].id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}


