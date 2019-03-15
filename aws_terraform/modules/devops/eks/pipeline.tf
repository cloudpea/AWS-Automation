resource "aws_iam_role" "codebuild_role" {
  count = "${signum(var.aws_pipeline)}"
  name = "kubernetes-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  count = "${signum(var.aws_pipeline)}"
  role = "${aws_iam_role.codebuild_role.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
			  "ecr:GetAuthorizationToken",
			  "ecr:InitiateLayerUpload",
			  "ecr:UploadLayerPart",
			  "ecr:CompleteLayerUpload",
			  "ecr:PutImage"
      ],
      "Resource": "${var.ecr_registry_arn}"
    }
  ]
}
POLICY
}

resource "aws_security_group" "codebuild_security_group" {
  count = "${signum(var.aws_pipeline)}"
  name        = "pipeline-codebuild-sg"
  description = "Default Code Build Security Group"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_codebuild_project" "codebuild" {
  count = "${signum(var.aws_pipeline)}"
  name          = "Build-Docker-Image"
  description   = "Builds Docker Images and Pushes to ECR."
  build_timeout = "60"
  service_role  = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:18.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name"  = "ECR_Registry"
      "value" = "${var.ecr_registry_name}"
      "type"  = "PLAINTEXT"
    }

    environment_variable {
      "name"  = "Image_Name"
      "value" = "${var.image_name}"
      "type"  = "PLAINTEXT"
    }

    environment_variable {
      "name"  = "Image_Tag"
      "value" = "${var.image_tag}"
      "type"  = "PLAINTEXT"
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  vpc_config {
    vpc_id = "${var.vpc_id}"

    subnets = [
      "${var.subnet_ids[0]}",
      "${var.subnet_ids[1]}",
    ]

    security_group_ids = [
      "${aws_security_group.codebuild_security_group.id}",
    ]
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  count = "${signum(var.aws_pipeline)}"
  bucket = "kubernetes-codepipeline-artifacts"
  acl    = "private"
}

resource "aws_iam_role" "codepipeline_role" {
  count = "${signum(var.aws_pipeline)}"
  name = "kubernetes-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  count = "${signum(var.aws_pipeline)}"
  name = "codepipeline_policy"
  role = "${aws_iam_role.codepipeline_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_bucket.arn}",
        "${aws_s3_bucket.codepipeline_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "codepipeline" {
  count = "${signum(var.aws_pipeline)}"
  name     = "kubernetes-codepipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codepipeline_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["Git"]

      configuration = {
        Owner      = "${var.github_owner}"
        Repo       = "${var.github_repo}"
        Branch     = "${var.github_branch}"
        OAuthToken = "${var.github_oauth_token}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["Git"]
      version          = "1"
      output_artifacts = ["DockerImage"]

      configuration = {
        ProjectName = "Build-Docker-Image"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["DockerImage"]
      version         = "1"

      configuration {
        FunctionName = "KubernetesDeploy"
      }
    }
  }
}
