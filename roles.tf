resource "aws_iam_role" "execution_role" {
  count              = var.launch_type == "FARGATE" ? 1 : 0
  name = "${var.APP_NAME}-ecs-iam-role"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = concat(var.additional_polices_fargate, [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
  ])

  tags = {
    Name = "${var.deployment_name}-ecs-execution_role"
  }
}



data "aws_iam_policy_document" "task_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "${var.deployment_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_assume_policy.json
  path               = "/"
}

data "aws_iam_policy_document" "service_role_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "service_role_policy" {
  statement {
    actions = concat(var.additional_polices_fargate,[
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress"
    ])
    resources = ["*"]
  }
}

resource "aws_iam_role" "service_role" {
  name               = "${var.deployment_name}-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_role_assume_policy.json
  path               = "/"

  inline_policy {
    name   = "${var.deployment_name}-service-policy"
    policy = data.aws_iam_policy_document.service_role_policy.json
  }
}

# IAM Role for EC2 instances
resource "aws_iam_instance_profile" "ec2" {
  count = var.launch_type == "EC2" ? 1 : 0
  name  = "${var.deployment_name}-ec2-instance-profile"
  role  = aws_iam_role.ec2[0].name
}

resource "aws_iam_role" "ec2" {
  count              = var.launch_type == "EC2" ? 1 : 0
  name               = "${var.deployment_name}-ec2-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_policy.json
  path               = "/"

  inline_policy {
    name   = "${var.deployment_name}-ec2-policy"
    policy = data.aws_iam_policy_document.ec2_policy.json
  }
}

data "aws_iam_policy_document" "ec2_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    actions = concat(var.additional_polices_ec2,[
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ])
    resources = ["*"]
  }
}
