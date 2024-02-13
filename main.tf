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

resource "aws_vpc" "terraform-eks-main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-eks-main"
  }
}

resource "aws_internet_gateway" "terraform-eks-igw" {
  vpc_id = aws_vpc.terraform-eks-main.id

  tags = {
    Name = "terraform-eks-igw"
  }
}

resource "aws_subnet" "terraform-eks-public-us-east-1a" {
  vpc_id                  = aws_vpc.terraform-eks-main.id
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
  vpc_id                  = aws_vpc.terraform-eks-main.id
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
  vpc_id            = aws_vpc.terraform-eks-main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                            = "terraform-eks-private-us-east-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

resource "aws_subnet" "terraform-eks-private-us-east-1c" {
  vpc_id            = aws_vpc.terraform-eks-main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                            = "terraform-eks-private-us-east-1c"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/demo"      = "owned"
  }
}

