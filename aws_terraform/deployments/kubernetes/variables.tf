# AWS Access Variables
variable "aws_access_key" {
  type = "string"
}

variable "aws_secret_key" {
  type = "string"
}

variable "aws_region" {
  type = "string"
}

# Generic Variables
variable "environment_tag" {
  type = "string"
}

variable "owner_tag" {
  type = "string"
}

# VPC Module Variables
variable "availability_zones" {
  type = "list"
}

variable "vpc_cidr" {
  type = "string"
}

variable "subnet_cidrs" {
  type = "list"
}

# EKS Module Variables
variable "cluster_name" {
  type = "string"
}

variable "key_name" {
  type = "string"
}

variable "node_size" {
  type = "string"
}

variable "min_nodes" {
  type = "string"
}

variable "max_nodes" {
  type = "string"
}

variable "desired_nodes" {
  type = "string"
}

# AWS Pipeline Module Variables
#variable "pipeline_vpc_id" {
#  type = "string"
#}
#
#variable "github_owner" {
#  type = "string"
#}
#
#variable "github_repo" {
#  type = "string"
#}
#
#variable "github_branch" {
#  type = "string"
#}
#
#variable "github_oauth_token" {
#  type = "string"
#}
#
#variable "image_name" {
#  type = "string"
#}
#
#variable "image_tag" {
#  type = "string"
#}
#
#variable "pipeline_application" {
#  type = "string"
#}
#
#variable "pipelin_deploy_env" {
#  type = "string"
#}

