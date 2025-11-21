# Assume role policy for ECS tasks
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS Task Execution Role (used by Fargate to pull images, write logs, etc.)
resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project}-${var.env}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# Attach AWS managed ECS task execution policy (required for CloudWatch Logs, ECR auth, etc.)
resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy allowing read-only ECR actions (keeps scope clearer for examples)
data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid     = "ECRRead"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name   = "${var.project}-${var.env}-ecr-pull"
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ecr_pull_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

# Optional: allow decrypt/read from Secrets Manager (comment/uncomment if you use secrets)
data "aws_iam_policy_document" "secretsmanager_access" {
  statement {
    sid = "SecretsManagerGet"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"] # Change to specific secret ARNs in production
  }
}

resource "aws_iam_policy" "secretsmanager_read" {
  count  = 0   # set to 1 if you want to attach this by default; left 0 to avoid surprise permissions
  name   = "${var.project}-${var.env}-secrets-read"
  policy = data.aws_iam_policy_document.secretsmanager_access.json
}

resource "aws_iam_role_policy_attachment" "secrets_read_attach" {
  count      = 0
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.secretsmanager_read[0].arn
}