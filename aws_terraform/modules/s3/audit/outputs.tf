output "audit_bucket_name" {
   value = "${aws_s3_bucket.audit_bucket.bucket}"
}
