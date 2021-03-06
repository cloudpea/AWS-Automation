variable "FortiGateS3Bucket" {}
variable "FortiGateKeyName" {}
#variable "FortiGate_Key_Pair" {}
variable "aws_region" {}
variable "infra_fortigate_bucket_name" {}
variable "infra_account_name" {}
#variable "billing_account_no" {}
variable "environment" {}
variable "owner_tag" {}
variable "customer_name" {}
variable "infra_account_no" {}
#variable "cloudtrail_bucket" {}

variable "FortiGateInstanceType" {}
variable "LicenseType"  {}
variable "FortiGateLicense1" {}
variable "FortiGateLicense2" {}
variable "FortiGateVpcCidrIp" {}
##variable "PublicSubnet1CIDR" {}
##variable "PublicSubnet2CIDR" {}
##variable "AutomateUser" {}
##variable "AutomateUserPwd" {}
variable "FortigateBGP" {}
variable "stack_name" {}

variable "spoke1_account_no" {}
variable "billing_account_no" {}
variable "audit_account_no" {}
variable "auth_account_no" {}
variable "FortiGatePublicSubnet1CIDR" {}
##variable "account_name" {}
variable "FortiGateAutomateUser" {}
variable "FortiGateAutomateUserPwd" {}
variable "FortiGatePublicSubnet2CIDR" {}
variable "aws_credentials_path" {}
variable "FortiGateS3ConfigBucket" {}
