provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

# Added variable cider block
variable "vpc-cidr-block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block range for vpc"
}

variable "public-subnet-cidr-blocks" {
  type = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "CIDR block range for the public subnet"
}

variable "private-subnet-cidr-blocks" {
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  description = "CIDR block range for the private subnet"
}

variable "availability-zones" {
  type  = list(string)
  default = ["us-east-1a", "us-east-1b"]
  description = "List of availability zones for the selected region"
}

resource "null_resource" "run-kubectl" {
  provisioner "local-exec" {
        command = "aws eks update-kubeconfig --region ${var.region}  --name ${var.cluster-name}"
  }
  depends_on = [resource.aws_eks_node_group.private-nodes]
}

resource "null_resource" "run-kubectl1" {
  provisioner "local-exec" {
        command = <<EOT
#        kubectl apply -f ~/learn-terraform-eks/a2024-namespace.yaml
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml    
        sleep 60
#        kubectl apply -f ~/learn-terraform-eks/mongo-deployment.yaml
#        kubectl apply -f ~/learn-terraform-eks/a2024-ingress.yaml
        sleep 60
        EOT
  }
  depends_on = [resource.null_resource.run-kubectl]
}


#change address
#resource "null_resource" "run-kubectl2" {
#  provisioner "local-exec" {
#        command = <<EOT
#        address=$(echo "$(kubectl get ingress -n a2024 | awk 'NR==2 {print $4}')")
#        sed -i.bak '/^ *- name: externalhost$/,/^ *value:/ s/value:.*/value: "'"$address"'"/' ~/learn-terraform-eks/a2024-deployment.yaml
#        kubectl apply -f ~/learn-terraform-eks/a2024-deployment.yaml
#        EOT
#  }
#  depends_on = [resource.null_resource.run-kubectl1]
#}

variable "cluster-name" {
  description = "This will ask you to name the cluster"
# uncomment this to use default
#  default = "terraform-eks-demo1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# Setup VPC and Subnet
resource "aws_vpc" "terraform-eks-vpc" {
  enable_dns_support = true
  enable_dns_hostnames = true
  cidr_block = var.vpc-cidr-block

  tags = {
    Name = "${var.cluster-name}-vpc"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

# Setup IGW and NAT
resource "aws_internet_gateway" "terraform-eks-igw" {
  vpc_id = aws_vpc.terraform-eks-vpc.id

  tags = {
    Name = "${var.cluster-name}-igw"
  }
}

resource "aws_eip" "terraform-eks-eip" {
  vpc = true

  tags = {
    Name = "${var.cluster-name}-eip"
  }
}

resource "aws_nat_gateway" "terraform-eks-nat" {
  allocation_id = aws_eip.terraform-eks-eip.id
  subnet_id     = aws_subnet.terraform-eks-public-subnet[0].id

  tags = {
    Name = "${var.cluster-name}-nat"
  }

  depends_on = [aws_internet_gateway.terraform-eks-igw]
}

resource "aws_subnet" "terraform-eks-public-subnet" {
  count                   = length(var.public-subnet-cidr-blocks)
  vpc_id                  = aws_vpc.terraform-eks-vpc.id
  cidr_block              = var.public-subnet-cidr-blocks[count.index]
  availability_zone       = var.availability-zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.cluster-name}-public-subnet"
    "kubernetes.io/role/elb"     = "1"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}

resource "aws_subnet" "terraform-eks-private-subnet" {
  count             = length(var.private-subnet-cidr-blocks)
  vpc_id            = aws_vpc.terraform-eks-vpc.id
  cidr_block        = var.private-subnet-cidr-blocks[count.index]
  availability_zone = var.availability-zones[count.index]

  tags = {
    Name = "${var.cluster-name}-private-subnet"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}

# Setup route table and association
resource "aws_route_table" "terraform-eks-private-rt" {
  vpc_id = aws_vpc.terraform-eks-vpc.id

  route {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.terraform-eks-nat.id
  }

  tags = {
    Name = "${var.cluster-name}-private-rt"
  }
}

resource "aws_route_table" "terraform-eks-public-rt" {
  vpc_id = aws_vpc.terraform-eks-vpc.id

  route {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.terraform-eks-igw.id
  }

  tags = {
    Name = "${var.cluster-name}-public-rt"
  }
}

resource "aws_route_table_association" "terraform-eks-public-subnet-rta" {
  count = length(var.availability-zones)
  subnet_id      = aws_subnet.terraform-eks-public-subnet[count.index].id
  route_table_id = aws_route_table.terraform-eks-public-rt.id
}

resource "aws_route_table_association" "terraform-eks-private-subnet-rta" {
  count = length(var.availability-zones)
  subnet_id      = aws_subnet.terraform-eks-private-subnet[count.index].id
  route_table_id = aws_route_table.terraform-eks-private-rt.id
}

# Setup AWS IAM Role for cluster
resource "aws_iam_role" "terraform-eks-role-cluster" {
  name = var.cluster-name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "terraform-eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.terraform-eks-role-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "terraform-eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.terraform-eks-role-cluster.name}"
}

# Setup cluster
resource "aws_eks_cluster" "terraform-eks-cluster" {
  name            = var.cluster-name
  role_arn        = aws_iam_role.terraform-eks-role-cluster.arn

  vpc_config {
    security_group_ids = [
      aws_security_group.terraform-eks-private-facing-sg.id
    ]
    subnet_ids         = [for subnet in aws_subnet.terraform-eks-public-subnet : subnet.id]
  }
  
  tags = {
    "Name" = "${var.cluster-name}-eks-cluster"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.terraform-eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.terraform-eks-cluster-AmazonEKSServicePolicy
  ]
}

# Create public facing security group
resource "aws_security_group" "terraform-eks-public-facing-sg" {
  vpc_id = aws_vpc.terraform-eks-vpc.id
  name   = "terraform-eks-public-facing-sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
#    protocol    = "-1"
    cidr_blocks = flatten([var.private-subnet-cidr-blocks, var.public-subnet-cidr-blocks])
#    cidr_blocks = ["0.0.0.0/0"]
    # Allow traffic from public subnet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {  
    Name = "${var.cluster-name}-public-facing-sg"
  }
}

# Create private facing security group
resource "aws_security_group" "terraform-eks-private-facing-sg" {
  vpc_id = aws_vpc.terraform-eks-vpc.id
  name   = "${var.cluster-name}-private-facing-sg"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol  = "-1"
    cidr_blocks = flatten(var.private-subnet-cidr-blocks)
#    cidr_blocks = ["0.0.0.0/0"]
    # Allow traffic from private subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster-name}-private-facing-sg"
  }
}

# KIV first, use aws eks cli to update konfig
# Create kubeconfig. This might help me run kubectl within tf
locals {
  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.terraform-eks-cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.terraform-eks-cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws-iam-authenticator
      args:
      - --region
      - "${var.region}"
      - eks
      - get-token
      - --cluster-name
      - "${var.cluster-name}"
      - --output
      - json
        - "token"
        - "-i"       
        command: aws
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}


# Setup Nodes
resource "aws_iam_role" "terraform-eks-nodes-role" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
        "Action": [
          "ec2:CreateVolume",
          "ec2:CreateTags",
          "ec2:AttachVolume"
         ],
        Effect   = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        },
      ]
    })  
}



resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.terraform-eks-nodes-role.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.terraform-eks-nodes-role.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.terraform-eks-nodes-role.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.terraform-eks-nodes-role.name
}

resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.terraform-eks-cluster.name
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.terraform-eks-nodes-role.arn

  subnet_ids = [for subnet in aws_subnet.terraform-eks-private-subnet : subnet.id]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  launch_template {
    name    = aws_launch_template.terraform-eks-demo.name
    version = aws_launch_template.terraform-eks-demo.latest_version
  }

  tags = {
    Name = "${var.cluster-name}-eks-cluster-node"
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
    Who = "Me"
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}

locals {
  demo-node-userdata = <<USERDATA
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==BOUNDARY=="

--==BOUNDARY==
Content-Type: text/cloud-config; charset="us-ascii"
#!/bin/bash
#Install ssm agent
if [[ $(uname -i) == "aarch64" ]]; then
  echo "arm"
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
else
  echo "amd"
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
fi
systemctl start amazon-ssm-agent
usermod -s /sbin/nologin ec2-user
--==BOUNDARY==--
USERDATA
}

resource "aws_launch_template" "terraform-eks-demo" {
  name = "eks-with-disks"
  user_data = "${base64encode(local.demo-node-userdata)}"

  block_device_mappings {
    device_name = "/dev/xvdb"

    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster-name}-eks-node-ec2"
    }
  }
}
