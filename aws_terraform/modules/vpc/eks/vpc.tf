### VPC Resources ###

# AWS VPC
resource "aws_vpc" "eks_vpc" {
  cidr_block = "${var.vpc_cidr}"

  tags {
    Name        = "kubernetes-vpc"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

# VPC Internet Gateway
resource "aws_internet_gateway" "eks_gw" {
  vpc_id = "${aws_vpc.eks_vpc.id}"

  tags {
    Name        = "kubernetes-igw"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

# VPC Default Route
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.eks_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.eks_gw.id}"
}

# VPC Kubernetes Subnets
resource "aws_subnet" "kubernetes_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.eks_vpc.id}"
  cidr_block        = "${var.subnet_cidrs[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"

  tags {
    Name        = "kubernetes-subnet-${count.index + 1}a"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

# Kubernetes Subnet Data
data "aws_subnet_ids" "kubernetes_subnets_ids" {
  vpc_id     = "${aws_vpc.eks_vpc.id}"
  depends_on = ["aws_subnet.kubernetes_subnets"]
}

# Kubernetes Subnets Route Table Association
resource "aws_route_table_association" "kubernetes_route_table_association" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${data.aws_subnet_ids.kubernetes_subnets_ids.ids[count.index]}"
  route_table_id = "${aws_vpc.eks_vpc.main_route_table_id}"
}

# Kubernetes Control Plane Security Group
resource "aws_security_group" "control_plane_security_group" {
  name        = "kubernetes-control-plane-sg"
  description = "Kubernetes Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.eks_vpc.id}"

  tags {
    Name        = "kubernetes-control-plane-sg"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}


### Outputs ###
output "vpc_id" {
  value = "${aws_vpc.eks_vpc.id}"
}
output "kubernetes_subnets" {
  value = "${data.aws_subnet_ids.kubernetes_subnets_ids.ids}"
}

output "security_group_id" {
  value = "${aws_security_group.control_plane_security_group.id}"
}




