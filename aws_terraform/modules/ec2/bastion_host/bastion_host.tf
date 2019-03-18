# Availability Zones
data "aws_availability_zones" "available" {}

# Linux Bastion Security Group
resource "aws_security_group" "linux_security_group" {
  count       = "${var.linux_host ? 1 : 0}"
  name        = "linux-bastion-host-sg"
  description = "Default Linux Bastion Host Security Group"
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

  tags {
    Name = "Linux-Bastion-Security-Group"
  }
}

# Windows Bastion Security Group
resource "aws_security_group" "windows_security_group" {
  count       = "${var.windows_host ? 1 : 0}"
  name        = "windows-bastion-host-sg"
  description = "Default Windows Bastion Host Security Group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "TCP"
    cidr_blocks = ["${var.corporate_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Windows-Bastion-Security-Group"
  }
}

# Latest Ubuntu 16.04 AMI
data "aws_ami" "latest_ubuntu" {
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

# Linux Bastion Shell Script
data "template_file" "linux_install" {
  template = "${file("${path.module}/linux_bastion_install.sh")}"
}

# Linux Bastion EC2 Instance
resource "aws_instance" "linux_bastion" {
  count                       = "${var.linux_host ? 1 : 0}"
  ami                         = "${data.aws_ami.latest_ubuntu.id}"
  instance_type               = "${var.instance_type}"
  availability_zone           = "${data.aws_availability_zones.available.names[0]}"
  monitoring                  = true
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.linux_security_group.id}"]
  subnet_id                   = "${var.subnet_id}"
  key_name                    = "${var.instance_key}"

  user_data = "${data.template_file.linux_install.rendered}"

  tags = {
    Name        = "Linux-Bastion-Host"
    Application = "Bastion"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}

# Latest Windows 2016 AMI
data "aws_ami" "latest_windows_2016" {
  most_recent = true
  owners      = ["amazon"] # Amazon

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Windows Bastion Powershell Script
data "template_file" "windows_install" {
  template = "${file("${path.module}/windows_bastion_install.ps1")}"
}

# Windows Bastion EC2 Instance
resource "aws_instance" "windows_bastion" {
  count                       = "${var.windows_host ? 1 : 0}"
  ami                         = "${data.aws_ami.latest_windows_2016.id}"
  instance_type               = "${var.instance_type}"
  availability_zone           = "${data.aws_availability_zones.available.names[0]}"
  monitoring                  = true
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.windows_security_group.id}"]
  subnet_id                   = "${var.subnet_id}"
  key_name                    = "${var.instance_key}"

  user_data = "${data.template_file.windows_install.rendered}"

  tags = {
    Name        = "Windows-Bastion-Host"
    Application = "Bastion"
    Environment = "${var.environment_tag}"
    Owner       = "${var.owner_tag}"
  }
}


# Outputs