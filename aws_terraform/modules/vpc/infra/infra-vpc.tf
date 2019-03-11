provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}


resource "aws_vpc" "infra_vpc" {
  provider   = "aws.infra"
  cidr_block = "${var.infra_vpc_cidr}"

  tags {
    Name        = "${var.infra_vpc_name}"
    Account     = "${var.infra_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
    Spoke_VPC   = "${var.spoke_vpc}"
  }
}


#resource "aws_internet_gateway" "infra_gw" {
#  provider = "aws.infra"
#  vpc_id = "${aws_vpc.infra_vpc.id}"

#  tags {
#    Name        = "${var.infra_vpc_name}-igw"
#    Account     = "${var.infra_account_name}"
#    Region      = "${var.aws_region}"
#    Environment = "${var.environment}"
#    Owner       = "${var.owner_tag}"
#    Spoke_VPC   = "${var.spoke_vpc}"
#  }
#}


resource "aws_vpn_gateway" "infra_vpn" {
  provider = "aws.infra"
  vpc_id = "${aws_vpc.infra_vpc.id}"

  tags {
   Name        = "${var.infra_vpc_name}-vpn-gw"
   Account     = "${var.infra_account_name}"
   Region      = "${var.aws_region}"
   Environment = "${var.environment}"
   Owner       = "${var.owner_tag}"
   Spoke_VPC   = "${var.spoke_vpc}"
  }
}

#resource "aws_route" "internet_access" {
#  provider = "aws.infra"
#  route_table_id          = "${aws_vpc.infra_vpc.main_route_table_id}"
#  destination_cidr_block  = "185.12.194.14/32"
#  gateway_id              = "${aws_internet_gateway.infra_gw.id}"
#}


resource "aws_default_route_table" "infra_route_prop" {
  provider = "aws.infra"
  default_route_table_id = "${aws_vpc.infra_vpc.default_route_table_id}"
  propagating_vgws = ["${aws_vpn_gateway.infra_vpn.id}"]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_vpn_gateway.infra_vpn.id}"
  }

  tags {
    Name = "infra default table"
  }
}


resource "aws_vpn_gateway_route_propagation" "infra_route_propagation" {
  provider = "aws.infra"
  vpn_gateway_id = "${aws_vpn_gateway.infra_vpn.id}"
  route_table_id = "${aws_default_route_table.infra_route_prop.default_route_table_id}"
}

