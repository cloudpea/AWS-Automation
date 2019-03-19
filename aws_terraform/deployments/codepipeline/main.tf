# Configure the AWS Provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

module "aws_pipeline" {
  source             = "../../modules/codepipeline/eks"
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

