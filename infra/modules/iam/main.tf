

# Create IAM Role for EC2 instances
resource "aws_iam_role" "blogapp_role" {
  name = var.custom_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = ["ecs-tasks.amazonaws.com",
         "ec2.amazonaws.com"] 
        }
      }
    ]
  })

  tags = {
    Project = "BlogApp"
  }
}

# Policy 1: EC2 + Infra permissions
resource "aws_iam_role_policy" "blogapp_policy1" {
  name = "blogapp_policy1"
  role = aws_iam_role.blogapp_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "cloudwatch:*",
          "autoscaling:*",
          "iam:CreateServiceLinkedRole"
        ],
        Resource = "*"
      }
    ]
  })
}

# Policy 2: Lambda + S3 access
resource "aws_iam_role_policy" "blogapp_policy2" {
  name = "blogapp_policy2"
  role = aws_iam_role.blogapp_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          // "s3:*",
          "s3-object-lambda:*"
        ],
        Resource = [
          "arn:aws:s3:::myaws3-buk",
          "arn:aws:s3:::myaws3-buk/*",
          "arn:aws:s3:::my-wemail-template",
          "arn:aws:s3:::my-wemail-template/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "*",
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Policy 3: SSM Parameter Store
resource "aws_iam_role_policy" "blogapp_policy3" {
  name = "blogapp_policy3"
  role = aws_iam_role.blogapp_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ],
        Resource = "arn:aws:ssm:eu-west-2:895581202168:parameter/blog-app/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeFunction"
        ],
        "Resource" : "arn:aws:lambda:eu-west-2:895581202168:function:welcomefunction"
      }

    ]
  })
}






# Create instance profile
resource "aws_iam_instance_profile" "blogapp_instance_profile" {
  name = "blogapp_instance_profile"
  role = aws_iam_role.blogapp_role.name
}
