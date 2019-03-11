provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}


#Create AWS Config Recorder
resource "aws_config_configuration_recorder" "config_recorder" {
  provider = "aws.infra"
  name     = "${var.config_recorder_name}"
  role_arn = "${aws_iam_role.config_recorder_role.arn}"
}

#Set up S3 Bucket for AWS Config
resource "aws_s3_bucket" "config_recorder_bucket" {
  provider = "aws.infra"
  bucket = "${var.config_recorder_name}-s3-bucket"
  force_destroy = true
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSConfigBucketPermissionsCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"
        ]
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${var.config_recorder_name}-s3-bucket"
    },
    {
      "Sid": " AWSConfigBucketDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": [
         "config.amazonaws.com"    
        ]
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.config_recorder_name}-s3-bucket/*",
      "Condition": { 
        "StringEquals": { 
          "s3:x-amz-acl": "bucket-owner-full-control" 
        }
      }
    }
  ]
}   
POLICY
}


#Enable AWS Config Recorder
resource "aws_config_configuration_recorder_status" "config_recorder_status" {
  provider = "aws.infra"
  name       = "${aws_config_configuration_recorder.config_recorder.name}"
  is_enabled = true
  depends_on = ["aws_config_delivery_channel.config_recorder_channel"]
}

#Point AWS Config delivery channel at config_recorder_bucket
resource "aws_config_delivery_channel" "config_recorder_channel" {
  provider = "aws.infra"
  name           = "${aws_config_configuration_recorder.config_recorder.name}"
  s3_bucket_name = "${aws_s3_bucket.config_recorder_bucket.bucket}"
}

#Create AWS Config Rule using built in required_tags function - Update input parameters to include up to 6 critical tags
resource "aws_config_config_rule" "required_tags" {
  provider = "aws.infra"
  name     = "${var.config_function_name}"

  source {
    owner             = "AWS"
    source_identifier = "${var.config_function_identifier}"
  }

  input_parameters = <<JSON
  {
    "tag1Key": "${var.tag1Key}",
    "tag2Key": "${var.tag2Key}",
    "tag3Key": "${var.tag3Key}"
  }
  JSON

  depends_on = ["aws_config_configuration_recorder.config_recorder"]
}

#Create Config Recorder IAM Role and Policy
resource "aws_iam_role" "config_recorder_role" {
  provider = "aws.infra"
  name = "${var.config_recorder_name}_role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "config_recorder_role_policy" {
  provider = "aws.infra"
  name = "${var.config_recorder_name}_role_policy"
  role = "${aws_iam_role.config_recorder_role.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": "config:Put*",
        "Effect": "Allow",
        "Resource": "*"
    }
  ]
}
POLICY
}

