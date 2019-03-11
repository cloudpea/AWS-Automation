provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}


#Create Infra IAM User Role - maps from opus_auth account
resource "aws_iam_role" "infra_role_role" {
  name = "${var.infra_iam_role_name}"
  provider = "aws.infra"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            },
            "Principal": {
                "AWS": "arn:aws:iam::${var.auth_account_no}:root"
            }
        }
    ]
}
POLICY
}


#Create Dev IAM User Role - maps from opus_auth account
resource "aws_iam_role" "spoke1_role_role" {
  name = "${var.spoke1_iam_role_name}"
  provider = "aws.infra"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Effect": "Allow",
            "Condition": {
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            },
            "Principal": {
                "AWS": "arn:aws:iam::${var.auth_account_no}:root"
            }
        }
    ]
}
POLICY
}


#Attaches infra_role_role to built in Admin IAM Policy
resource "aws_iam_role_policy_attachment" "infra-attach" {
    provider   = "aws.infra"
    role       = "${aws_iam_role.infra_role_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#Attaches spoke1_role_role to built in ReadOnly IAM Policy
resource "aws_iam_role_policy_attachment" "spoke1-attach" {
    provider   = "aws.infra"
    role       = "${aws_iam_role.spoke1_role_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

