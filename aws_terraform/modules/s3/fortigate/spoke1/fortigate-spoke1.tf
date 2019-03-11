provider "aws" {
  alias = "spoke1"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "spoke1"
}


#Deploy the FortiGate Transit VPC Secondary Account Template - Taking the FortiGateS3Bucket output as an input
resource "aws_cloudformation_stack" "FortiGate_Transit_Secondary" {
provider = "aws.spoke1"
name = "${var.stack_name}"
 
parameters {
S3BucketName = "${var.FortiGateS3ConfigBucket}"
TagStack = "${var.stack_name}"
TagPrimaryOwner = "${var.owner_tag}"
TagCreated = "21st June 2018"
}
 
template_body = "${file("${path.module}/TransitVPC_SecondAccount.template.json")}"
 
capabilities = ["CAPABILITY_IAM"]
 
tags {
Name = "${var.stack_name}"
Account = "${var.infra_account_name}"
Region = "${var.aws_region}"
Environment = "${var.environment}"
Owner = "${var.owner_tag}"
}
}
