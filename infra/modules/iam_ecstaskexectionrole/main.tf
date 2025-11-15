# ECS Task Execution Role
resource "aws_iam_role" "ecstaskexecution_role" {
  name = "blogapp-ecstaskexecution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "BlogApp"
  }
}

# Policy 1: SSM Parameter Store
resource "aws_iam_role_policy" "taskesecution_policy1" {
  name = "taskesecution_policy1"
  role = aws_iam_role.ecstaskexecution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:eu-west-2:895581202168:parameter/blog-app/*"
      }
    ]
  })
}

# Policy 2: Managed ECS Task Execution Role Policy (includes ECR access + CloudWatch logs)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecstaskexecution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}




