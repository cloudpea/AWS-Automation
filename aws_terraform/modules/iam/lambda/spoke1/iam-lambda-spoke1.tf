provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}

provider "aws" {
  alias = "spoke1"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "spoke1"
}


#Get central AWS Account identity
data "aws_caller_identity" "central_account" {
  provider = "aws.infra"
}

#Get child AWS Account identity
data "aws_caller_identity" "child_account" {
  provider = "aws.spoke1"
}

#Create randon external id for role condition
resource "random_string" "external_id_1" {
  length  = 64
  special = false
}

resource "random_string" "external_id_2" {
  length  = 64
  special = false
}

#Create IAM Role for Lambda function ops-functions-populate-resource-tags-child-resources
resource "aws_iam_role" "populate_resource_tags_child_resources" {
  name     = "populate_resource_tags_child_resources"
  provider = "aws.spoke1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.central_account.account_id}:root"
      },
      "Effect": "Allow",
      "Condition": {
          "StringEquals": {
              "sts:ExternalId": "${random_string.external_id_1.result}"
          }
      }
    }
  ]
}
  EOF
}

#Create IAM Role for Lambda function ops-functions-populate-resource-tags-on-creation
resource "aws_iam_role" "populate_resource_tags_on_creation" {
  name     = "populate_resource_tags_on_creation"
  provider = "aws.spoke1"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.central_account.account_id}:root"
      },
      "Effect": "Allow",
      "Condition": {
          "StringEquals": {
              "sts:ExternalId": "${random_string.external_id_2.result}"
          }
      }
    }
  ]
}
  EOF
}

#Create Policy with permissions for Lambda function ops-functions-populate-resource-tags-child-resources
resource "aws_iam_policy" "populate_resource_tags_child_resources_policy" {
  name     = "populate_resource_tags_child_resources_policy"
  provider = "aws.spoke1"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Action": ["ec2:DescribeInstances", "ec2:DescribeSnapshots", "ec2:CreateTags"],
      "Resource": "*"
  }]
}
  EOF
}

#Create Policy with permissions for Lambda function ops-functions-populate-resource-tags-on-creation
resource "aws_iam_policy" "populate_resource_tags_on_creation_policy" {
  name     = "populate_resource_tags_on_creation_policy"
  provider = "aws.spoke1"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Action": ["ec2:CreateTags", "ec2:DescribeInstances"],
      "Resource": "*"
  }]
}
  EOF
}


resource "aws_cloudwatch_event_permission" "populate_resource_tags_on_creation_event_permission" {
  provider     = "aws.infra"
  principal    = "${data.aws_caller_identity.child_account.account_id}"
  statement_id = "${data.aws_caller_identity.child_account.account_id}"
}


#Copy file to bucket
resource "aws_s3_bucket_object" "ops_functions_bucket_copy" {
  provider = "aws.infra"
  bucket   = "${var.OpsFunctionsS3Bucket}"
  key      = "/${var.OpsFunctionsS3BucketAccountsPath}/${data.aws_caller_identity.child_account.account_id}.json"
  content  = "{\"id\":\"${data.aws_caller_identity.child_account.account_id}\",\"externalIds\":{\"${aws_iam_role.populate_resource_tags_child_resources.name}\":\"${random_string.external_id_1.result}\",\"${aws_iam_role.populate_resource_tags_on_creation.name}\":\"${random_string.external_id_2.result}\"}}"
}

