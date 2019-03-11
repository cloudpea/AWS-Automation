provider "aws" {
  alias = "audit"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "audit"
}

resource "aws_s3_bucket" "audit_bucket" {
  provider = "aws.audit"
  bucket = "${var.audit_bucket_name}"
  region = "${var.aws_region}"
  acl    = "private"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::cloudtrail-core-audit"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": [
        "arn:aws:s3:::cloudtrail-core-audit/CloudTrail/AWSLogs/${var.audit_account_no}/*",
        "arn:aws:s3:::cloudtrail-core-audit/CloudTrail/AWSLogs/${var.billing_account_no}/*",
        "arn:aws:s3:::cloudtrail-core-audit/CloudTrail/AWSLogs/${var.auth_account_no}/*",
        "arn:aws:s3:::cloudtrail-core-audit/CloudTrail/AWSLogs/${var.infra_account_no}/*",
        "arn:aws:s3:::cloudtrail-core-audit/CloudTrail/AWSLogs/${var.spoke1_account_no}/*"
      ],
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}

POLICY

  force_destroy = true

  tags {
    Name        = "${var.audit_bucket_name}"
    Account     = "${var.audit_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}
