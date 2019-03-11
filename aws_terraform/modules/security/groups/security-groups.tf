provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}



# Bastion Security Group to provide access to Bastion Hosts
resource "aws_security_group" "bastion_sg" {
  provider = "aws.infra"
  name        = "bastion_sg"
  description = "Bastion Security Group"
  vpc_id = "${var.infra_vpc_id}"

  # RDP access from anywhere
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Any port to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Web DMZ Security Group to provide HTTP and HTTPS access from the outside world
resource "aws_security_group" "web_dmz_sg" {
  provider = "aws.infra"
  name        = "web_dmz_sg"
  description = "Web DMZ Security Group"
  vpc_id = "${var.infra_vpc_id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from Bastion Hosts
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RDP access from Bastion Hosts
    ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }

  # Any port to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion Security Group to provide access to Bastion Hosts
resource "aws_security_group" "private_sg" {
  provider = "aws.infra"
  name        = "private_sg"
  description = "Private Security Group"
  vpc_id = "${var.infra_vpc_id}"

  # SSH access from Bastion Hosts
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }

  # RDP access from Bastion Hosts
    ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    security_groups = ["${aws_security_group.bastion_sg.id}"]
  }
}
