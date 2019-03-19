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

variable "ecr_registry_name" {
  type = "string"
}

variable "ecr_registry_arn" {
  type = "string"
}

variable "image_name" {
  type = "string"
}

variable "image_tag" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "application" {
  type = "string"
}

variable "deploy_env" {
  type = "string"
}

variable "owner_tag" {
  type = "string"
}

variable "environment_tag" {
  type = "string"
}
