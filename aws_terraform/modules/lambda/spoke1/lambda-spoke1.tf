provider "aws" {
  alias = "spoke1"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "spoke1"
}


#Get central AWS Account identity
data "aws_caller_identity" "central_account" {
  provider = "aws.spoke1"
}


#Create CloudWatch LogGroup for ops-functions-populate-resource-tags-child-resources
resource "aws_cloudwatch_log_group" "populate_resource_tags_child_resources_spoke1" {
  name     = "/aws/lambda/populate_resource_tags_child_resources_spoke1"
  provider = "aws.spoke1"
}

#Create CloudWatch LogGroup for ops-functions-populate-resource-tags-on-creation
resource "aws_cloudwatch_log_group" "populate_resource_tags_on_creation_spoke1" {
  name     = "/aws/lambda/populate_resource_tags_on_creation_spoke1"
  provider = "aws.spoke1"
}

#Create IAM Role for Lambda function ops-functions-populate-resource-tags-child-resources
resource "aws_iam_role" "populate_resource_tags_child_resources_spoke1" {
  name     = "populate_resource_tags_child_resources_spoke1"
  provider = "aws.spoke1"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
            "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  EOF
}

#Create IAM Role for Lambda function ops-functions-populate-resource-tags-on-creation
resource "aws_iam_role" "populate_resource_tags_on_creation_spoke1" {
  name     = "populate_resource_tags_on_creation_spoke1"
  provider = "aws.spoke1"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
            "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  EOF
}

#Create Policy with permissions for Lambda function ops-functions-populate-resource-tags-child-resources
resource "aws_iam_policy" "populate_resource_tags_child_resources_policy_spoke1" {
  name     = "populate_resource_tags_child_resources_policy_spoke1"
  provider = "aws.spoke1"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::*:role/populate_resource_tags_child_resources_spoke1"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.OpsFunctionsS3Bucket}",
        "arn:aws:s3:::${var.OpsFunctionsS3Bucket}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.OpsFunctionsS3Bucket}/${var.OpsFunctionsS3BucketAccountsPath}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeSnapshots",
        "ec2:CreateTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
  EOF
}

#Create Policy with permissions for Lambda function ops-functions-populate-resource-tags-on-creation
resource "aws_iam_policy" "populate_resource_tags_on_creation_policy_spoke1" {
  name     = "populate_resource_tags_on_creation_policy_spoke1"
  provider = "aws.spoke1"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::*:role/populate_resource_tags_on_creation_spoke1"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${var.OpsFunctionsS3Bucket}/${var.OpsFunctionsS3BucketAccountsPath}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags",
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
  EOF
}

#Attaches populate_resource_tags_child_resource to populate_resource_tags_child_resources_policy
resource "aws_iam_role_policy_attachment" "populate_resource_tags_child_resources_policy_attach_role_spoke1" {
  provider   = "aws.spoke1"
  role       = "${aws_iam_role.populate_resource_tags_child_resources_spoke1.name}"
  policy_arn = "${aws_iam_policy.populate_resource_tags_child_resources_policy_spoke1.arn}"
}

#Attaches populate_resource_tags_on_creation_role to populate_resource_tags_on_creation_policy
resource "aws_iam_role_policy_attachment" "populate_resource_tags_on_creation_policy_attach_role_spoke1" {
  provider   = "aws.spoke1"
  role       = "${aws_iam_role.populate_resource_tags_on_creation_spoke1.name}"
  policy_arn = "${aws_iam_policy.populate_resource_tags_on_creation_policy_spoke1.arn}"
}

#Create Cloudwatch event rule to trigger populate_resource_tags_on_creation
resource "aws_cloudwatch_event_rule" "populate_resource_tags_on_creation_event_rule_spoke1" {
  provider    = "aws.spoke1"
  name        = "populate_resource_tags_on_creation_rule_spoke1"
  description = "This event will trigger on EC2 RunInstance events"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "source": [
    "aws.ec2"
  ],
  "detail": {
    "eventSource": [
      "ec2.amazonaws.com"
    ],
    "eventName": [
      "RunInstances"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "populate_resource_tags_on_creation_event_target_spoke1" {
  provider  = "aws.spoke1"
  rule      = "${aws_cloudwatch_event_rule.populate_resource_tags_on_creation_event_rule_spoke1.name}"
  target_id = "populate_resource_tags_on_creation_lambda_spoke1"
  arn       = "${aws_lambda_function.populate_resource_tags_on_creation_lambda_spoke1.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  provider      = "aws.spoke1"
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.populate_resource_tags_on_creation_lambda_spoke1.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.populate_resource_tags_on_creation_event_rule_spoke1.arn}"
}

#Create Cloudwatch event rule to trigger populate_resource_tags_child_resources
resource "aws_cloudwatch_event_rule" "populate_resource_tags_child_resources_rule_spoke1" {
  provider    = "aws.spoke1"
  name        = "populate_resource_tags_child_resources_rule_spoke1"
  description = "This schedule event will run every day"

  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "populate_resource_tags_child_resources_target_spoke1" {
  provider  = "aws.spoke1"
  rule      = "${aws_cloudwatch_event_rule.populate_resource_tags_child_resources_rule_spoke1.name}"
  target_id = "populate_resource_tags_child_resources_lambda_spoke1"
  arn       = "${aws_lambda_function.populate_resource_tags_child_resources_lambda_spoke1.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_child_spoke1" {
  provider      = "aws.spoke1"
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.populate_resource_tags_child_resources_lambda_spoke1.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.populate_resource_tags_child_resources_rule_spoke1.arn}"
}

#Create the Lambda function for populate_resource_tags_on_creation
resource "aws_lambda_function" "populate_resource_tags_on_creation_lambda_spoke1" {
  provider      = "aws.spoke1"
  filename      = "${path.module}/populateResourceTags.zip"
  function_name = "populate_resource_tags_on_creation_spoke1"
  role          = "${aws_iam_role.populate_resource_tags_on_creation_spoke1.arn}"
  handler       = "handlers/populate_resource_tags_handler.populateResourceTagsOnCreation"
  runtime       = "nodejs6.10"
  timeout       = 20
  memory_size   = 256

  environment {
    variables {
      tags             = "${var.tags}"
      bucketName       = "${var.OpsFunctionsS3Bucket}"
      centralAccountId = "${data.aws_caller_identity.central_account.account_id}"
      childRole        = "populate_resource_tags_on_creation_spoke1"
      s3Region         = "${var.aws_region}"
      s3Prefix         = "${var.OpsFunctionsS3BucketAccountsPath}"
    }
  }
}

#Create the Lambda function for populate_resource_tags_child_resources
resource "aws_lambda_function" "populate_resource_tags_child_resources_lambda_spoke1" {
  provider      = "aws.spoke1"
  filename      = "${path.module}/populateResourceTags.zip"
  function_name = "populate_resource_tags_child_resources_spoke1"
  role          = "${aws_iam_role.populate_resource_tags_child_resources_spoke1.arn}"
  handler       = "handlers/populate_resource_tags_handler.populateResourceTagsChildResources"
  runtime       = "nodejs6.10"
  timeout       = 120
  memory_size   = 256

  environment {
    variables {
      tags             = "${var.tags}"
      bucketName       = "${var.OpsFunctionsS3Bucket}"
      centralAccountId = "${data.aws_caller_identity.central_account.account_id}"
      childRole        = "populate_resource_tags_child_resources_spoke1"
      s3Region         = "${var.aws_region}"
      s3Prefix         = "${var.OpsFunctionsS3BucketAccountsPath}"
    }
  }
}
