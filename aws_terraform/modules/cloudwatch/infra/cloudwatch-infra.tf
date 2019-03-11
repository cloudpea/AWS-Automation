provider "aws" {
  alias = "infra"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "infra"
}

#Create CloudWatch LogGroup for ops-functions-populate-resource-tags-child-resources
resource "aws_cloudwatch_log_group" "populate_resource_tags_child_resources" {
  name     = "/aws/lambda/populate_resource_tags_child_resources"
  provider = "aws.infra"
}

#Create CloudWatch LogGroup for ops-functions-populate-resource-tags-on-creation
resource "aws_cloudwatch_log_group" "populate_resource_tags_on_creation" {
  name     = "/aws/lambda/populate_resource_tags_on_creation"
  provider = "aws.infra"
}


#Create Cloudwatch event rule to trigger populate_resource_tags_on_creation
resource "aws_cloudwatch_event_rule" "populate_resource_tags_on_creation_event_rule" {
  provider    = "aws.infra"
  name        = "populate_resource_tags_on_creation_rule"
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

resource "aws_cloudwatch_event_target" "populate_resource_tags_on_creation_event_target" {
  provider  = "aws.infra"
  rule      = "${aws_cloudwatch_event_rule.populate_resource_tags_on_creation_event_rule.name}"
  target_id = "populate_resource_tags_on_creation_lambda"
  arn       = "${aws_lambda_function.populate_resource_tags_on_creation_lambda.arn}"
}

#Create Cloudwatch event rule to trigger populate_resource_tags_child_resources
resource "aws_cloudwatch_event_rule" "populate_resource_tags_child_resources_rule" {
  provider    = "aws.infra"
  name        = "populate_resource_tags_child_resources_rule"
  description = "This schedule event will run every day"

  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "populate_resource_tags_child_resources_target" {
  provider  = "aws.infra"
  rule      = "${aws_cloudwatch_event_rule.populate_resource_tags_child_resources_rule.name}"
  target_id = "populate_resource_tags_child_resources_lambda"
  arn       = "${aws_lambda_function.populate_resource_tags_child_resources_lambda.arn}"
}




