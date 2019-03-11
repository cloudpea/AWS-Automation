provider "aws" {
  alias = "auth"
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials_path}"
  profile                 = "auth"
}



#Create SAML Provider to link to Azure AD - Using generated Drax Azure AD Metadata file.
resource "aws_iam_saml_provider" "customer_azuread" {
  provider               = "aws.auth"
  name                   = "${var.identity_provider_name}"
  saml_metadata_document = "${file("${path.module}/aws-cloud-start.xml")}"
}

#Create IAM Policy for Customer Azure AD SSO User
resource "aws_iam_policy" "azure_ssouser_policy" {
  name = "${var.azure_ssouser_policy}"
  provider = "aws.auth"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

#Create IAM User for Customer Azure AD SSO User
resource "aws_iam_user" "azure_ssouser" {
  name = "${var.azure_ssouser}"
  provider = "aws.auth"
}
#THIS HAS NOW BEEN CREATED MANUALLY TO PREVENT DECOUPLING FROM AZURE AD ON REBUILD

#Attach Drax Azure AD SSO User to Policy
resource "aws_iam_policy_attachment" "ssouser_attach_policy" {
  provider   = "aws.auth"
  name       = "ssouser_attach_policy"
  users      = ["AzureADRoleManager"]
  policy_arn = "${aws_iam_policy.azure_ssouser_policy.arn}"
  depends_on = ["aws_iam_user.azure_ssouser"]
}

#Create role for Billing Users
resource "aws_iam_role" "billing_assume_role" {
  name = "${var.billing_assume_role_name}"
  provider = "aws.auth"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRoleWithSAML",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "SAML:aud": "https://signin.aws.amazon.com/saml"
                }
            },
            "Principal": {
                "Federated": "arn:aws:iam::${var.auth_account_no}:saml-provider/AzureADIdentityProvider"
            }
        }
    ]
}
POLICY
}

#Create role for Sec Users
resource "aws_iam_role" "security_assume_role" {
  name = "${var.security_assume_role_name}"
  provider = "aws.auth"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRoleWithSAML",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "SAML:aud": "https://signin.aws.amazon.com/saml"
                }
            },
            "Principal": {
                "Federated": "arn:aws:iam::${var.auth_account_no}:saml-provider/AzureADIdentityProvider"
            }
        }
    ]
}
POLICY
}

#Create role for Infra Users
resource "aws_iam_role" "infra_assume_role" {
  name = "${var.infra_assume_role_name}"
  provider = "aws.auth"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRoleWithSAML",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "SAML:aud": "https://signin.aws.amazon.com/saml"
                }
            },
            "Principal": {
                "Federated": "arn:aws:iam::${var.auth_account_no}:saml-provider/AzureADIdentityProvider"
            }
        }
    ]
}
POLICY
}

#Create role for Spoke1 Users
resource "aws_iam_role" "spoke1_assume_role" {
  name = "${var.spoke1_assume_role_name}"
  provider = "aws.auth"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRoleWithSAML",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "SAML:aud": "https://signin.aws.amazon.com/saml"
                }
            },
            "Principal": {
                "Federated": "arn:aws:iam::${var.auth_account_no}:saml-provider/AzureADIdentityProvider"
            }
        }
    ]
}
POLICY
}


#Create Billing Policy with IAM permissions into multiple accounts
resource "aws_iam_policy" "billing_assume_role_policy" {
  name = "${var.billing_assume_role_name}_policy"
  provider = "aws.auth"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.billing_account_no}:role/billing_role"
        }
    ]
}
POLICY
}

#Create Security Policy with IAM permissions into sec account
resource "aws_iam_policy" "security_assume_role_policy" {
  name = "${var.security_assume_role_name}_policy"
  provider = "aws.auth"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.audit_account_no}:role/security_role"
        }
    ]
}
POLICY
}

#Create Infra Policy with IAM permissions into multiple accounts
resource "aws_iam_policy" "infra_assume_role_policy" {
  name = "${var.infra_assume_role_name}_policy"
  provider = "aws.auth"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.billing_account_no}:role/${var.infra_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.auth_account_no}:role/${var.infra_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.audit_account_no}:role/${var.infra_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.infra_account_no}:role/${var.infra_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.spoke1_account_no}:role/${var.infra_role}"
        }
    ]
}
POLICY
}

#Create Spoke1 Policy with IAM permissions into multiple accounts
resource "aws_iam_policy" "spoke1_assume_role_policy" {
  name = "${var.spoke1_assume_role_name}_policy"
  provider = "aws.auth"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.billing_account_no}:role/${var.spoke1_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.auth_account_no}:role/${var.spoke1_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.audit_account_no}:role/${var.spoke1_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.infra_account_no}:role/${var.spoke1_role}"
        },
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::${var.spoke1_account_no}:role/${var.spoke1_role}"
        }
    ]
}

POLICY
}

#Attaches billing_assume_role to billing_assume_role_policy
resource "aws_iam_role_policy_attachment" "billing-attach-role" {
    provider   = "aws.auth"
    role       = "${aws_iam_role.billing_assume_role.name}"
    policy_arn = "${aws_iam_policy.billing_assume_role_policy.arn}"
}

#Attaches security_assume_role to security_assume_role_policy
resource "aws_iam_role_policy_attachment" "sec-attach-role" {
    provider   = "aws.auth"
    role       = "${aws_iam_role.security_assume_role.name}"
    policy_arn = "${aws_iam_policy.security_assume_role_policy.arn}"
}

#Attaches infra_assume_role to infra_assume_role_policy
resource "aws_iam_role_policy_attachment" "infra-attach-role" {
    provider   = "aws.auth"
    role       = "${aws_iam_role.infra_assume_role.name}"
    policy_arn = "${aws_iam_policy.infra_assume_role_policy.arn}"
}

#Attaches spoke1 to spoke1_assume_role_policy
resource "aws_iam_role_policy_attachment" "spoke1-attach-role" {
    provider   = "aws.auth"
    role       = "${aws_iam_role.spoke1_assume_role.name}"
    policy_arn = "${aws_iam_policy.spoke1_assume_role_policy.arn}"
}

