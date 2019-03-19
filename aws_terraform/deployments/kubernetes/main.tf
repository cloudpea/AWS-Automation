# Configure the AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# Configure the Template Provider
provider "template" {}

# Configure the Null Provider
provider "null" {}

module "vpc" {
  source             = "../../modules/vpc/eks"
  availability_zones = "${var.availability_zones}"
  vpc_cidr           = "${var.vpc_cidr}"
  subnet_cidrs       = "${var.subnet_cidrs}"
  environment_tag    = "${var.environment_tag}"
  owner_tag          = "${var.owner_tag}"
}

module "cluster" {
  source             = "../../modules/eks"
  eks_region         = "${var.aws_region}"
  cluster_name       = "${var.cluster_name}"
  key_name           = "${var.key_name}"
  node_size          = "${var.node_size}"
  min_nodes          = "${var.min_nodes}"
  max_nodes          = "${var.max_nodes}"
  desired_nodes      = "${var.desired_nodes}"
  environment_tag    = "${var.environment_tag}"
  owner_tag          = "${var.owner_tag}"
  vpc_id             = "${module.vpc.vpc_id}"
  kubernetes_subnets = "${module.vpc.kubernetes_subnets}"
  security_group_id  = "${module.vpc.security_group_id}"
}