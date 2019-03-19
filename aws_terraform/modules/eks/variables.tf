variable "eks_region" {
  type = "string"
}

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

variable "owner_tag" {
  type = "string"
}

variable "environment_tag" {
  type = "string"
}

variable "kubernetes_subnets" {
  type = "list"
}

variable "vpc_id" {
  type = "string"
}

variable "security_group_id" {
  type = "string"
}
