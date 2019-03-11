provider "aws" {
  alias = "audit"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "audit"
}


resource "aws_cloudtrail" "cloudtrail_logs" {
  provider                      = "aws.audit"
  name                          = "cloudtrail_core_logging"
  s3_bucket_name                = "${var.cloudtrail_bucket}"
  s3_key_prefix                 = "CloudTrail"
  include_global_service_events = true
  is_multi_region_trail         = true

  event_selector {
    read_write_type = "All"
    include_management_events = true

    data_resource {
      type = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}
