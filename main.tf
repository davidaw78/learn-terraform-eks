provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "cluster-name" {
  default = "terraform-eks-demo"
}

# Setup VPC and Subnet
resource "aws_vpc" "terraform-eks-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-eks-vpc"
  }
}

# Setup IGW and NAT
resource "aws_internet_gateway" "terraform-eks-igw" {
  vpc_id = aws_vpc.terraform-eks-vpc.id

  tags = {
    Name = "terraform-eks-igw"
  }
}

resource "aws_eip" "terraform-eks-eip" {
  vpc = true

  tags = {
    Name = "terraform-eks-eip"
  }
}

resource "aws_nat_gateway" "terraform-eks-nat" {
  allocation_id = aws_eip.terraform-eks-eip.id
  subnet_id     = aws_subnet.terraform-eks-public-us-east-1a.id

  tags = {
    Name = "terraform-eks-nat"
  }

  depends_on = [aws_internet_gateway.terraform-eks-igw]
}


resource "aws_subnet" "terraform-eks-public-us-east-1a" {
  vpc_id                  = aws_vpc.terraform-eks-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "terraform-eks-public-us-east-1a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}

resource "aws_subnet" "terraform-eks-public-us-east-2a" {
  vpc_id                  = aws_vpc.terraform-eks-vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    "Name"                       = "terraform-eks-public-us-east-2a"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/demo" = "owned"
  }
}


resource "aws_subnet" "terraform-eks-private-us-east-1b" {
  vpc_id            = aws_vpc.terraform-eks-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                            = "terraform-eks-private-us-east-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "terraform-eks-private-us-east-1c" {
  vpc_id            = aws_vpc.terraform-eks-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                            = "terraform-eks-private-us-east-1c"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

# Setup route table and association
resource "aws_route_table" "terraform-eks-private-rt" {
  vpc_id = aws_vpc.terraform-eks-vpc.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.terraform-eks-nat.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      gateway_id                 = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "terraform-eks-private-rt"
  }
}

resource "aws_route_table" "terraform-eks-public-rt" {
  vpc_id = aws_vpc.terraform-eks-vpc.id

  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.terraform-eks-igw.id
      nat_gateway_id             = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
    },
  ]

  tags = {
    Name = "terraform-eks-public-rt"
  }
}

resource "aws_route_table_association" "public-us-east-1a-rta" {
  subnet_id      = aws_subnet.terraform-eks-public-us-east-1a.id
  route_table_id = aws_route_table.terraform-eks-public-rt.id
}

resource "aws_route_table_association" "public-us-east-2a-rta" {
  subnet_id      = aws_subnet.terraform-eks-public-us-east-2a.id
  route_table_id = aws_route_table.terraform-eks-public-rt.id
}

resource "aws_route_table_association" "terraform-eks-private-us-east-1b-rta" {
  subnet_id      = aws_subnet.terraform-eks-private-us-east-1b.id
  route_table_id = aws_route_table.terraform-eks-private-rt.id
}

resource "aws_route_table_association" "terraform-eks-private-us-east-1c-rta" {
  subnet_id      = aws_subnet.terraform-eks-private-us-east-1c.id
  route_table_id = aws_route_table.terraform-eks-private-rt.id
}
