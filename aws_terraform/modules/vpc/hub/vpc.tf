provider "aws" {
  alias = "hub"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "hub"
}


resource "aws_vpc" "hub_vpc" {
  provider   = "aws.hub"
  cidr_block = "${var.hub_vpc_cidr}"

  tags {
    Name        = "${var.hub_vpc_name}"
    Account     = "${var.hub_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}


resource "aws_internet_gateway" "hub_gw" {
  provider = "aws.hub"
  vpc_id = "${aws_vpc.hub_vpc.id}"
  tags {
    Name        = "${var.hub_vpc_name}-igw"
    Account     = "${var.hub_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}


resource "aws_vpn_gateway" "hub_vpn" {
  provider = "aws.hub"
  vpc_id = "${aws_vpc.hub_vpc.id}"

  tags {
   Name        = "${var.hub_vpc_name}-vpn-gw"
   Account     = "${var.hub_account_name}"
   Region      = "${var.aws_region}"
   Environment = "${var.environment}"
   Owner       = "${var.owner_tag}"
  }
}

resource "aws_route" "internet_access" {
  provider = "aws.hub"
  route_table_id          = "${aws_vpc.hub_vpc.main_route_table_id}"
  destination_cidr_block  = "185.12.194.14/32"
  gateway_id              = "${aws_internet_gateway.hub_gw.id}"
}


resource "aws_default_route_table" "hub_route_prop" {
  provider = "aws.hub"
  default_route_table_id = "${aws_vpc.hub_vpc.default_route_table_id}"
  propagating_vgws = ["${aws_vpn_gateway.hub_vpn.id}"]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_vpn_gateway.hub_vpn.id}"
  }

  tags {
    Name = "hub default table"
  }
}


resource "aws_vpn_gateway_route_propagation" "hub_route_propagation" {
  provider = "aws.hub"
  vpn_gateway_id = "${aws_vpn_gateway.hub_vpn.id}"
  route_table_id = "${aws_default_route_table.hub_route_prop.default_route_table_id}"
}

