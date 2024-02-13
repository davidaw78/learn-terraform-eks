variable "cluster-name" {
  default = "terraform-eks-demo"
}

# Will explore what does shared mean.
# Setup VPC layer
resource "aws_vpc" "terraform-eks-demo-vpc" {
  cidr_block = "10.0.0.0/16" # 65,534 ip addresses

  tags = "${
    map(
     "Name", "terraform-eks-demo-node-vpc",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

# Count = 2 means produce 2 subnet?
resource "aws_subnet" "terraform-eks-demo-subnet" {
  count = 2

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.terraform-eks-demo-vpc.id}"

  tags = "${
    map(
     "Name", "terraform-eks-demo-node-subnet",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "terraform-eks-demo-igw" {
  vpc_id = "${aws_vpc.terraform-eks-demo-vpc.id}"

  tags = {
    Name = "terraform-eks-demo-igw"
  }
}

resource "aws_route_table" "terraform-eks-demo-rt" {
  vpc_id = "${aws_vpc.terraform-eks-demo-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terraform-eks-demo-igw.id}"
  }
}

resource "aws_route_table_association" "terraform-eks-demo-rta" {
  count = 2

  subnet_id      = "${aws_subnet.terraform-eks-demo-subnet.*.id[count.index]}"
  route_table_id = "${aws_route_table.terraform-eks-demo-rt.id}"
}
