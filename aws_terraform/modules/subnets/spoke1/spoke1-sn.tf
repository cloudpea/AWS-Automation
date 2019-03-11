provider "aws" {
  alias = "spoke1"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "spoke1"
}


#Create the First Private Subnet
resource "aws_subnet" "spoke1_private1_subnet" {
  provider = "aws.spoke1"
  vpc_id     = "${var.spoke1_vpc_id}"
  cidr_block = "${var.spoke1_private1_subnet_cidr}"
  availability_zone = "${var.spoke1_availability_zone_a}"
  tags {
    Name        = "${var.spoke1_subnet_name}-private1"
    Account     = "${var.spoke1_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}

# Create the Second Private Subnet
resource "aws_subnet" "spoke1_private2_subnet" {
  provider = "aws.spoke1"
  vpc_id     = "${var.spoke1_vpc_id}"
  cidr_block = "${var.spoke1_private2_subnet_cidr}"
  availability_zone = "${var.spoke1_availability_zone_b}"
  tags {
    Name        = "${var.spoke1_subnet_name}-private2"
    Account     = "${var.spoke1_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}

