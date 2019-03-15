# Configure the AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "bastion_host" {
  source          = "../../modules/ec2/bastion_host"
  windows_host    = "${var.windows_host}"
  linux_host      = "${var.linux_host}"
  instance_type   = "${var.instance_type}"
  vpc_id          = "${var.vpc_id}"
  subnet_id       = "${var.subnet_id}"
  corporate_ip    = "${var.corporate_ip}"
  vm_username     = "${var.vm_username}"
  instance_key    = "${var.instance_key}"
  environment_tag = "${var.environment_tag}"
  owner_tag       = "${var.owner_tag}"
}
