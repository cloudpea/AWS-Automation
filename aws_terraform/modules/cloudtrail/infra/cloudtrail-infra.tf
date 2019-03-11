provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}


#Configure CloudTrail to point as opus_sec logging bucket
resource "aws_cloudtrail" "cloudtrail_logs" {
  provider                      = "aws.infra"
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
