provider "aws" {
  alias = "billing"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "billing"
}

resource "aws_s3_bucket" "billing_bucket" {
  provider = "aws.billing"
  bucket = "${var.billing_bucket_name}"
  region = "${var.aws_region}"
  acl    = "private"
  #policy = "${file("${path.module}/s3_bucket_policy_billing.json")}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.billing_account_no}"
      },
      "Action": [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy"
      ],
      "Resource": "arn:aws:s3:::${var.customer_name}-billing-bucket"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.billing_account_no}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::billing-bucket/*"
    }
    ]
}
POLICY
  force_destroy = true

  tags {
    Name        = "${var.billing_bucket_name}"
    Account     = "${var.billing_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}
