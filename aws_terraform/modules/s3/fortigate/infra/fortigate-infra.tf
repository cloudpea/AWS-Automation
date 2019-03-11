provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}


#Create EC2 KeyPair for CloudFormation Input Parameter
resource "aws_key_pair" "FortiGate_Key_Pair" {
  provider = "aws.infra"
  key_name = "${var.FortiGateKeyName}"
  public_key = "${file("${path.module}/FortiGate_Key_Pair.pub")}"
}

#Create S3 Bucket for storing configuration and license files
resource "aws_s3_bucket" "infra_fortigate_bucket" {
  provider = "aws.infra"
  bucket = "${var.FortiGateS3Bucket}"
  region = "${var.aws_region}"
  acl    = "private"
  #acl    = "public-read"
  #policy = "${file("${path.module}/s3_bucket_policy_fortigate.json")}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${var.infra_account_no}"
        ]
      },
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${var.customer_name}-fortigate-source"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${var.infra_account_no}"
        ]
      },
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${var.customer_name}-fortigate-source/*"
    }
    ]
}
POLICY
  force_destroy = true

  tags {
    Name        = "${var.FortiGateS3Bucket}"
    Account     = "${var.infra_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}


#Upload License Files to S3 Bucket
resource "aws_s3_bucket_object" "FortiGate_License1" {
  provider = "aws.infra"
  bucket = "${aws_s3_bucket.infra_fortigate_bucket.id}"
  key    = "${var.FortiGateLicense1}"
  source = "${var.FortiGateLicense1}"
  #source   = "${file("${path.module}/${var.FortiGateLicense1}")}"
  etag   = "${md5(file("${path.module}/${var.FortiGateLicense1}"))}"
}


resource "aws_s3_bucket_object" "FortiGate_License2" {
  provider = "aws.infra"
  bucket = "${aws_s3_bucket.infra_fortigate_bucket.id}"
  key    = "${var.FortiGateLicense2}"
  #source = "${path.module}/${var.FortiGateLicense2})}"
  source   = "${var.FortiGateLicense2}"
  etag   = "${md5(file("${path.module}/${var.FortiGateLicense2}"))}"
}



#resource "aws_s3_bucket_object" "FortiGate_License1" {
#  provider = "aws.infra"
#  bucket = "${aws_s3_bucket.infra_fortigate_bucket.id}"
#  key    = "${var.FortiGateLicense1}"
#  content = "${path.module}/${var.FortiGateLicense1})}"
#  server_side_encryption = "aws:kms"
  #etag   = "${md5(file("${path.module}/${var.FortiGateLicense1}"))}"
  #key    = "FGVM4V0000162594.lic"
  #content = "${path.module}/FGVM4V0000162594.lic)}"
  #etag   = "${md5(file("${path.module}/FGVM4V0000162594.lic"))}"
#}

#resource "aws_s3_bucket_object" "FortiGate_License2" {
#  provider = "aws.infra"
#  bucket = "${aws_s3_bucket.infra_fortigate_bucket.id}"
#  key    = "${var.FortiGateLicense2}"
#  content = "${path.module}/${var.FortiGateLicense2})}"
#  server_side_encryption = "aws:kms"
  #etag   = "${md5(file("${path.module}/${var.FortiGateLicense2}"))}"
  #key    = "FGVM4V0000162595.lic"
  #content = "${path.module}/FGVM4V0000162595.lic)}"
  #etag   = "${md5(file("${path.module}/FGVM4V0000162595.lic"))}"
#}

#Deploy the FortiGate Transit VPC CloudFormation tempate - Taking inputs from variables file
resource "aws_cloudformation_stack" "FortiGate_Transit_Primary" {
  provider = "aws.infra"
  name = "${var.stack_name}"

  parameters {
    FortiGateKeyName = "${aws_key_pair.FortiGate_Key_Pair.key_name}"
    FortiGateInstanceType = "${var.FortiGateInstanceType}"
    LicenseType = "BYOL"
    #SourceS3Bucket = "${aws_s3_bucket.infra_fortigate_bucket.id}"
    SourceS3Bucket = "fortigate-source"
    SourceS3BucketRegion = "${var.aws_region}"
    Fgt1LicenseFile = "${aws_s3_bucket_object.FortiGate_License1.key}"
    Fgt2LicenseFile = "${aws_s3_bucket_object.FortiGate_License2.key}"
    VpcCidrIp = "${var.FortiGateVpcCidrIp}"
    PublicSubnet1CIDR = "${var.FortiGatePublicSubnet1CIDR}"
    PublicSubnet2CIDR = "${var.FortiGatePublicSubnet2CIDR}"
    AutomateUser = "${var.FortiGateAutomateUser}"
    AutomateUserPwd = "${var.FortiGateAutomateUserPwd}"
    BGP = "${var.FortigateBGP}"
    SpokeTag = "Spoke_VPC"
    SpokeTagValue = "true"
    TagStack = "${var.stack_name}"
    TagPrimaryOwner = "${var.owner_tag}"
    TagCreated = "7th August 2018"
  }

  template_body = "${file("${path.module}/TransitVPC_PrimaryAccount_NewVPC.template.json")}"

  capabilities = ["CAPABILITY_IAM"]

  tags {
    Name        = "${var.stack_name}"
    Account     = "${var.infra_account_name}"
    Region      = "${var.aws_region}"
    Environment = "${var.environment}"
    Owner       = "${var.owner_tag}"
  }
}



resource "aws_s3_bucket_policy" "fortigate_config_bucket_policy" {
  provider = "aws.infra"
  bucket = "${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["S3Bucket"]}"
  policy =<<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${var.billing_account_no}:root",
                    "arn:aws:iam::${var.audit_account_no}:root",
                    "arn:aws:iam::${var.auth_account_no}:root",
                    "arn:aws:iam::${var.infra_account_no}:root",
                    "arn:aws:iam::${var.spoke1_account_no}:root"
                ]
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["S3Bucket"]}/*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${var.billing_account_no}:root",
                    "arn:aws:iam::${var.audit_account_no}:root",
                    "arn:aws:iam::${var.auth_account_no}:root",
                    "arn:aws:iam::${var.infra_account_no}:root",
                    "arn:aws:iam::${var.spoke1_account_no}:root"
                ]
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["S3Bucket"]}/*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.infra_account_no}:role/${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["MainLambdaRole"]}"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["S3Bucket"]}/*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.infra_account_no}:role/${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["WorkerConfigLambdaRole"]}"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["S3Bucket"]}/*"
        }
    ]
}
POLICY
}

