
### IAM Resources ###

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# EKS IAM Role Cluster Policy Attachment
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks_cluster_role.name}"
}

# EKS IAM Role Service Policy Attachment
resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks_cluster_role.name}"
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# EKS IAM Role Node Policy Attachment
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks_node_role.name}"
}

# EKS IAM Role CNI Policy Attachment
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks_node_role.name}"
}

# EKS IAM Role ECR Policy Attachment
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks_node_role.name}"
}

# EKS Node IAM Instance Profile
resource "aws_iam_instance_profile" "eks_instance_profile" {
  name = "eks-instance-profile"
  role = "${aws_iam_role.eks_node_role.name}"
}


### VPC Resources ###

# EKS Node Security Group
resource "aws_security_group" "eks_node_security_group" {
  name        = "eks-node-sg"
  description = "Security group for all nodes in the cluster"

  vpc_id = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "eks-node-sg",
     "kubernetes.io/cluster/${var.cluster_name}", "owned",
    )
  }"
}

# EKS Node Security Group Rule Self Ingress
resource "aws_security_group_rule" "eks_node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks_node_security_group.id}"
  source_security_group_id = "${aws_security_group.eks_node_security_group.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# EKS Node Security Group Rule Cluster Ingress
resource "aws_security_group_rule" "eks_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_node_security_group.id}"
  source_security_group_id = "${var.security_group_id}"
  to_port                  = 65535
  type                     = "ingress"
}

# EKS Control Plane Security Group Rule Cluster Ingress
resource "aws_security_group_rule" "eks_cluster_ingress_cluster" {
  description              = "Allow cluster control plane to receive communication from the worker Kubelets and pods"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${var.security_group_id}"
  source_security_group_id = "${aws_security_group.eks_node_security_group.id}"
  to_port                  = 65535
  type                     = "ingress"
}

# EKS Control Plane Security Group Rule Cluster Engress
resource "aws_security_group_rule" "eks_cluster_egress_cluster" {
  description              = "Allow cluster control plane to send communication to the worker Kubelets and pods"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${var.security_group_id}"
  source_security_group_id = "${aws_security_group.eks_node_security_group.id}"
  to_port                  = 65535
  type                     = "egress"
}


### Compute Resources

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name = "${var.cluster_name}"

  role_arn = "${aws_iam_role.eks_cluster_role.arn}"

  vpc_config {
    subnet_ids         = ["${var.kubernetes_subnets}"]
    security_group_ids = ["${var.security_group_id}"]
  }
}

# EKS Node AMI
data "aws_ami" "eks-worker-node" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

#EKS Node User Data
locals {
  eks-node-userdata = <<EOF
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh ${var.cluster_name}
EOF
}

#EKS Node Launch Configuration
resource "aws_launch_configuration" "eks_node_launch_config" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.eks_instance_profile.name}"
  image_id                    = "${data.aws_ami.eks-worker-node.id}"
  instance_type               = "${var.node_size}"
  key_name                    = "${var.key_name}"
  name_prefix                 = "eks-node-launch-configuration"
  security_groups             = ["${aws_security_group.eks_node_security_group.id}"]
  user_data_base64            = "${base64encode(local.eks-node-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

#EKS Node AutoScaling Group
resource "aws_autoscaling_group" "eks_node_autoscaling_group" {
  desired_capacity     = "${var.desired_nodes}"
  launch_configuration = "${aws_launch_configuration.eks_node_launch_config.id}"
  max_size             = "${var.min_nodes}"
  min_size             = "${var.max_nodes}"
  name                 = "eks-node-autoscaling-group"
  vpc_zone_identifier  = ["${var.kubernetes_subnets}"]

  tag {
    key                 = "Name"
    value               = "eks-worker-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  depends_on = ["aws_eks_cluster.eks_cluster"]
}

### Container Registry Resources ###

# Elastic Container Registry
resource "aws_ecr_repository" "ecr_repository" {
  name = "kubernetes-images"
}

# Elastic Container Registry Policy
resource "aws_ecr_repository_policy" "ecr_repository_policy" {
  repository = "${aws_ecr_repository.ecr_repository.name}"

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

### Kubernetes Configuration ###

# AWS Auth ConfigMap
data "template_file" "aws_auth_cm" {
  template = "${file("${path.module}/aws-auth-cm.yaml")}"

  vars {
    node_role_arn = "${aws_iam_role.eks_node_role.arn}"
  }
}

# Local CLI Command to Configure EKS Cluster
resource "null_resource" "kubectl_config" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.eks_region} update-kubeconfig --name ${var.cluster_name}"
  }

  provisioner "local-exec" {
    command = "echo \"${data.template_file.aws_auth_cm.rendered}\" > ${path.module}/${var.cluster_name}-aws-auth-cm.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/${var.cluster_name}-aws-auth-cm.yaml"
  }

  depends_on = [
    "aws_eks_cluster.eks_cluster"
  ]
}

### Outputs ###

output "endpoint" {
  value = "${aws_eks_cluster.eks_cluster.endpoint}"
}

output "ecr_name" {
  value = "${aws_ecr_repository.ecr_repository.name}"
}

output "ecr_arn" {
  value = "${aws_ecr_repository.ecr_repository.arn}"
}
