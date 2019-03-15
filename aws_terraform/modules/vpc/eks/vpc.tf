resource "aws_vpc" "eks_vpc" {
  cidr_block = "${var.vpc_cidr}"

  tags {
    Name        = "kubernetes-vpc"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

resource "aws_internet_gateway" "eks_gw" {
  vpc_id = "${aws_vpc.eks_vpc.id}"

  tags {
    Name        = "kubernetes-igw"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.eks_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.eks_gw.id}"
}

resource "aws_subnet" "kubernetes_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.eks_vpc.id}"
  cidr_block        = "${var.kubernetes_subnet_cidrs[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"

  tags {
    Name        = "kubernetes-subnet-${count.index}a"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}
data "aws_subnet_ids" "kubernetes_subnets_ids" {
  vpc_id     = "${aws_vpc.eks_vpc.id}"
  depends_on = ["aws_subnet.kubernetes_subnets"]
}

resource "aws_subnet" "pipeline_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.eks_vpc.id}"
  cidr_block        = "${var.pipeline_subnet_cidrs[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"

  tags {
    Name        = "pipeline-subnet-${count.index}a"
    Application = "Kubernetes"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

data "aws_subnet_ids" "pipeline_subnets_ids" {
  vpc_id     = "${aws_vpc.eks_vpc.id}"
  depends_on = ["aws_subnet.pipeline_subnets"]
}

resource "aws_route_table_association" "kubernetes_route_table_association" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${data.aws_subnet_ids.kubernetes_subnets_ids.ids[count.index]}"
  route_table_id = "${aws_vpc.eks_vpc.main_route_table_id}"
}

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

output "vpc_id" {
  value = "${aws_vpc.eks_vpc.id}"
}
output "kubernetes_subnets" {
  value = "${data.aws_subnet_ids.kubernetes_subnets_ids.ids}"
}

output "pipeline_subnets" {
  value = "${data.aws_subnet_ids.pipeline_subnets_ids.ids}"
}

output "security_group_id" {
  value = "${aws_security_group.control_plane_security_group.id}"
}




