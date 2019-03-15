variable "aws_pipeline" {}
variable "github_owner" {}
variable "github_repo" {}
variable "github_branch" {}
variable "github_oauth_token" {}
variable "ecr_registry_name" {}
variable "ecr_registry_arn" {}
variable "image_name" {}
variable "image_tag" {}
variable "vpc_id" {}
variable "subnet_ids" {
    type = "list"
}
variable "application" {}
variable "deploy_env" {}
variable "owner_tag" {}
variable "environment_tag" {}

