provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}


# Create the First Private Subnet
resource "aws_subnet" "infra_private1_subnet" {
  provider   = "aws.infra"
  vpc_id     = "${var.infra_vpc_id}"
  cidr_block = "${var.infra_private1_subnet_cidr}"
  #availability_zone = "${lookup(var.infra_availability_zone_a, var.aws_region)}"
  availability_zone = "${var.infra_availability_zone_a}"
  tags {
    Name        = "${var.infra_subnet_name}-private1"
    Account     = "${var.infra_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}

# Create the Second Private Subnet
resource "aws_subnet" "infra_private2_subnet" {
  provider   = "aws.infra"
  vpc_id     = "${var.infra_vpc_id}"
  cidr_block = "${var.infra_private2_subnet_cidr}"
  availability_zone = "${var.infra_availability_zone_b}"
  tags {
    Name        = "${var.infra_subnet_name}-private2"
    Account     = "${var.infra_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}
