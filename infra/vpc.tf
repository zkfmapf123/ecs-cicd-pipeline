resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true # Enable DNS resolution for the VPC
  enable_dns_hostnames = true # Enable DNS hostnames for the VPC
  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${local.prefix}-igw"
  }
}

resource "aws_subnet" "publics" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = {
    Name = "${local.prefix}-${each.key}-public"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_mapping" {
  for_each = aws_subnet.publics

  subnet_id      = each.value.id
  route_table_id = aws_route_table.rt.id

}