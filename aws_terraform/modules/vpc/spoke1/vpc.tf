provider "aws" {
  alias = "spoke1"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "spoke1"
}

# Create the VPC taking in a variable of the CIDR range
resource "aws_vpc" "spoke1_vpc" {
  provider = "aws.spoke1"
  cidr_block = "${var.spoke1_vpc_cidr}"

  tags {
    Name        = "${var.spoke1_vpc_name}"
    Account     = "${var.spoke1_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
    Spoke_VPC   = "${var.spoke1_vpc}"
  }
}

resource "aws_vpn_gateway" "spoke1_vpn" {
  provider = "aws.spoke1"
  vpc_id = "${aws_vpc.spoke1_vpc.id}"

  tags {
    Name        = "${var.spoke1_vpc_name}-gw"
    Account     = "${var.spoke1_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
    Spoke_VPC   = "${var.spoke1_vpc}"
  }
}


resource "aws_default_route_table" "spoke1_route_prop" {
  provider = "aws.spoke1"
  default_route_table_id = "${aws_vpc.spoke1_vpc.default_route_table_id}"
  propagating_vgws = ["${aws_vpn_gateway.spoke1_vpn.id}"]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_vpn_gateway.spoke1_vpn.id}"
  }

  tags {
    Name = "spoke1 default table"
  }
}


resource "aws_vpn_gateway_route_propagation" "spoke1_route_propagation" {
  provider = "aws.spoke1"
  vpn_gateway_id = "${aws_vpn_gateway.spoke1_vpn.id}"
  route_table_id = "${aws_default_route_table.spoke1_route_prop.default_route_table_id}"
}

