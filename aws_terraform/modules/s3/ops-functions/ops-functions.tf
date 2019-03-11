provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}

#Create S3 Bucket for storing auto tagging accounts json files
resource "aws_s3_bucket" "infra_ops_functions_bucket" {
  provider      = "aws.infra"
  bucket        = "${var.OpsFunctionsS3Bucket}"
  region        = "${var.aws_region}"
  acl           = "private"
  force_destroy = true

  tags {
    Name    = "${var.OpsFunctionsS3Bucket}"
    Account = "${var.infra_account_name}"
    Region  = "${var.aws_region}"
    Owner   = "${var.owner_tag}"
  }
}
