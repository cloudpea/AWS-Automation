variable "vpc_id" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "corporate_ip" {
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

variable "environment_tag" {
  type = "string"
}

variable "owner_tag" {
  type = "string"
}
