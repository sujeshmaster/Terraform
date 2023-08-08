# Create VPC
resource "aws_vpc" "dev_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.vpc_name}"
  }
}

# Create public subnets
resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.dev_vpc.id
  count                   = length(var.azs)
  cidr_block              = element(var.pub_subnet_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_name[0]}-${count.index + 1}"
  }

  depends_on = [aws_vpc.dev_vpc]
}

# Create internet gateway
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "${var.igw_name}"
  }

  depends_on = [aws_subnet.public_subnets]
}

# Create public route tables 
resource "aws_route_table" "public_RT" {
  count  = length(var.pub_subnet_cidr)
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "${var.RT_name[0]}-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.dev_igw]
}

# public route tables association with public subnets
resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_RT[count.index].id

  depends_on = [aws_route_table.public_RT]
}

# Create private subnets
resource "aws_subnet" "private_subnets" {
  vpc_id                  = aws_vpc.dev_vpc.id
  count                   = length(var.azs)
  cidr_block              = element(var.prt_subnet_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.subnet_name[1]}-${count.index + 1}"
  }

  depends_on = [aws_route_table_association.public_association]
}

# Create EIP
resource "aws_eip" "nat_eip" {
  vpc = true

  depends_on = [aws_subnet.private_subnets]
}

# Create NAT gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name = "${var.NAT_name}"
  }

  depends_on = [aws_eip.nat_eip]
}

# Create private route tables 
resource "aws_route_table" "private_RT" {
  count = length(var.prt_subnet_cidr)
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "${var.RT_name[1]}-${count.index+1}"
  }

  depends_on = [aws_nat_gateway.nat_gateway]
}

# public route tables association with private subnets
resource "aws_route_table_association" "private_association" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_RT[count.index].id

  depends_on = [aws_route_table.private_RT]
}