# Configure the AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "devops_agents" {
  source              = "../../modules/ec2/devops_agent"
  instance_type       = "${var.instance_type}"
  vpc_id              = "${var.vpc_id}"
  subnet_ids          = "${var.subnet_ids}"
  corporate_ip        = "${var.corporate_ip}"
  instance_key        = "${var.instance_key}"
  devops_organisation = "${var.devops_organisation}"
  devops_pat          = "${var.devops_pat}"
  devops_pool_name    = "${var.devops_pool_name}"
  environment_tag     = "${var.environment_tag}"
  owner_tag           = "${var.owner_tag}"
}
