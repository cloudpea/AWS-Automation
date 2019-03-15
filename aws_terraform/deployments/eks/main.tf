# Configure the AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "vpc" {
  source                  = "../../modules/vpc/eks"
  availability_zones      = "${var.availability_zones}"
  vpc_cidr                = "${var.vpc_cidr}"
  kubernetes_subnet_cidrs = "${var.kubernetes_subnet_cidrs}"
  pipeline_subnet_cidrs   = "${var.pipeline_subnet_cidrs}"
  environment_tag         = "${var.environment_tag}"
  owner_tag               = "${var.owner_tag}"
}

module "cluster" {
  source             = "../../modules/eks"
  eks_region         = "${var.aws_region}"
  cluster_name       = "${var.cluster_name}"
  node_size          = "${var.node_size}"
  environment_tag    = "${var.environment_tag}"
  owner_tag          = "${var.owner_tag}"
  vpc_id             = "${module.vpc.vpc_id}"
  kubernetes_subnets = "${module.vpc.kubernetes_subnets}"
  security_group_id  = "${module.vpc.security_group_id}"
}

module "aws_pipeline" {
  source             = "../../modules/devops/eks"
  aws_pipeline        = "${var.aws_pipeline}"
  github_owner       = "${var.github_owner}"
  github_repo        = "${var.github_repo}"
  github_branch      = "${var.github_branch}"
  github_oauth_token = "${var.github_oauth_token}"
  ecr_registry_name  = "${module.cluster.ecr_name}"
  ecr_registry_arn   = "${module.cluster.ecr_arn}"
  image_name         = "${var.image_name}"
  image_tag          = "${var.image_tag}"
  vpc_id             = "${var.pipeline_vpc_id}"
  subnet_ids         = "${module.vpc.pipeline_subnets}"
  application        = "${var.pipeline_application}"
  deploy_env         = "${var.pipelin_deploy_env}"
  environment_tag    = "${var.environment_tag}"
  owner_tag          = "${var.owner_tag}"
}

module "azure_pipeline" {
  source              = "../../modules/ec2/devops_agent"
  azure_pipeline       = "${var.azure_pipeline}"
  vpc_id              = "${var.pipeline_vpc_id}"
  subnet_ids          = "${module.vpc.pipeline_subnets}"
  corporate_ip        = "${var.corporate_ip}"
  instance_type       = "${var.agent_size}"
  instance_key        = "${var.instance_key}"
  devops_organisation = "${var.devops_organisation}"
  devops_pat          = "${var.devops_pat}"
  devops_pool_name    = "${var.devops_pool_name}"
  environment_tag     = "${var.environment_tag}"
  owner_tag           = "${var.owner_tag}"
}
