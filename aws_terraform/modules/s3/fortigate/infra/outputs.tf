output "FortiGateS3ConfigBucket" {
value = "${aws_cloudformation_stack.FortiGate_Transit_Primary.outputs["S3Bucket"]}"
}
