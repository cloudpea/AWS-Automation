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
variable "environment_tag" {}

variable "owner_tag" {}

# VPC Module Variables
variable "availability_zones" {}

variable "vpc_cidr" {}
variable "kubernetes_subnet_cidrs" {}
variable "pipeline_subnet_cidrs" {}

# EKS Module Variables
variable "cluster_name" {}

variable "node_size" {}

# Generic Pipeline Module Variables
variable "pipeline_vpc_id" {
  type = "string"
}

# AWS Pipeline Module Variables
variable "aws_pipeline" {
  type = "string"
}

variable "github_owner" {
  type = "string"
}

variable "github_repo" {
  type = "string"
}

variable "github_branch" {
  type = "string"
}

variable "github_oauth_token" {
  type = "string"
}

variable "image_name" {
  type = "string"
}

variable "image_tag" {
  type = "string"
}

variable "pipeline_application" {
  type = "string"
}

variable "pipelin_deploy_env" {
  type = "string"
}

# Azure Pipeline Module Variables
variable "azure_pipeline" {
  type = "string"
}

variable "corporate_ip" {
  type = "string"
}

variable "agent_size" {
  type = "string"
}

variable "instance_key" {
  type = "string"
}

variable "devops_organisation" {
  type = "string"
}

variable "devops_pat" {
  type = "string"
}

variable "devops_pool_name" {
  type = "string"
}
