# Configure the AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

module "eks_vpc" {
  source               = "../../modules/vpc/eks"
  "availability_zones" = "${var.availability_zones}"
  "eks_vpc_cidr"       = "${var.eks_vpc_cidr}"
  "eks_subnet_cidrs"   = "${var.eks_subnet_cidrs}"
  "environment_tag"    = "${var.environment_tag}"
  "owner_tag"          = "${var.owner_tag}"
}

module "eks_cluster" {
  source               = "../../modules/eks"
  "availability_zones" = "${var.availability_zones}"
  "environment_tag"    = "${var.environment_tag}"
  "owner_tag"          = "${var.owner_tag}"
}