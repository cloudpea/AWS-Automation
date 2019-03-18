data "aws_availability_zones" "available" {}

resource "aws_security_group" "security_group" {
  name        = "devops-agent-sg"
  description = "Default Azure DevOps Agent Security Group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["${var.corporate_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "agent_install" {
  template = "${file("${path.module}/InstallDevopsAgent.sh")}"

  vars {
    vm_username         = "ubuntu"
    devops_organisation = "${var.devops_organisation}"
    devops_pat          = "${var.devops_pat}"
    devops_pool_name    = "${var.devops_pool_name}"
  }
}

resource "aws_instance" "devops_agent_1" {
  ami                         = "${data.aws_ami.latest-ubuntu.id}"
  instance_type               = "${var.instance_type}"
  availability_zone           = "${data.aws_availability_zones.available.names[0]}"
  monitoring                  = true
  associate_public_ip_address = false
  vpc_security_group_ids      = ["${aws_security_group.security_group.id}"]
  subnet_id                   = "${var.subnet_ids[0]}"
  key_name                    = "${var.instance_key}"

  user_data = "${data.template_file.agent_install.rendered}"

  tags = {
    Name        = "Azure-DevOps-Agent-1"
    Application = "Azure DevOps"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

resource "aws_instance" "devops_agent_2" {
  ami                         = "${data.aws_ami.latest-ubuntu.id}"
  instance_type               = "${var.instance_type}"
  availability_zone           = "${data.aws_availability_zones.available.names[1]}"
  monitoring                  = true
  associate_public_ip_address = false
  vpc_security_group_ids      = ["${aws_security_group.security_group.id}"]
  subnet_id                   = "${var.subnet_ids[1]}"
  key_name                    = "${var.instance_key}"

  user_data = "${data.template_file.agent_install.rendered}"

  tags = {
    Name        = "Azure-DevOps-Agent-2"
    Application = "Azure DevOps"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}
