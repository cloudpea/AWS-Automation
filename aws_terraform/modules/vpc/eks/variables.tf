variable "availability_zones" {
  type = "list"
}

variable "vpc_cidr" {
  type = "string"
}

variable "subnet_cidrs" {
  type = "list"
}

variable "environment_tag" {
  type = "string"
}

variable "owner_tag" {
  type = "string"
}
