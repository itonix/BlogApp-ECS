

# ///creating an IAM role for for autoscaling group instances-rather than attaching policies to the instance profile directly\\\\\


# resource "aws_iam_role" "test_role" {
#   name = var.custom_role

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })

#   tags = {
#     tag-key = "tag-value"
#   }
# }

# #policy1-attaching multiple policies to the role created above\\\\\
# resource "aws_iam_role_policy" "test_role_policy1" {
#   name = "test_policy1"
#   role = aws_iam_role.test_role.name

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Action" : "ec2:*",
#         "Effect" : "Allow",
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : "elasticloadbalancing:*",
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : "cloudwatch:*",
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : "autoscaling:*",
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : "iam:CreateServiceLinkedRole",
#         "Resource" : "*",
#         "Condition" : {
#           "StringEquals" : {
#             "iam:AWSServiceName" : [
#               "autoscaling.amazonaws.com",
#               "ec2scheduled.amazonaws.com",
#               "elasticloadbalancing.amazonaws.com",

#             ]
#           }
#         }
#       }
#     ]
#   })
# }

# #policy2-attaching for s3 and s3-lambda to the role created above\\\\\

# resource "aws_iam_role_policy" "test_role_policy2" {
#   name = "test_policy2"
#   role = aws_iam_role.test_role.id

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "cloudformation:DescribeStacks",
#           "cloudformation:ListStackResources",
#           "cloudwatch:ListMetrics",
#           "cloudwatch:GetMetricData",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeVpcs",
#           "kms:ListAliases",
#           "iam:GetPolicy",
#           "iam:GetPolicyVersion",
#           "iam:GetRole",
#           "iam:GetRolePolicy",
#           "iam:ListAttachedRolePolicies",
#           "iam:ListRolePolicies",
#           "iam:ListRoles",
#           "lambda:*",
#           "logs:DescribeLogGroups",
#           "states:DescribeStateMachine",
#           "states:ListStateMachines",
#           "tag:GetResources",
#         ],
#         "Resource" : "*"
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : "iam:PassRole",
#         "Resource" : "*",
#         "Condition" : {
#           "StringEquals" : {
#             "iam:PassedToService" : "lambda.amazonaws.com"
#           }
#         }
#       },
#       {
#         "Effect" : "Allow",
#         "Action" : [
#           "logs:DescribeLogStreams",
#           "logs:GetLogEvents",
#           "logs:FilterLogEvents",
#           "logs:StartLiveTail",
#           "logs:StopLiveTail"
#         ],
#         "Resource" : "arn:aws:logs:*:*:log-group:/aws/lambda/*"
#       }
#     ]
#   })
# }

# ///policy3-attaching for SSM related access to the role created above\\\\\

# resource "aws_iam_role_policy" "test_policy3" {
#   name = "test_policy3"
#   role = aws_iam_role.test_role.id

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "VisualEditor0",
#         "Effect" : "Allow",
#         "Action" : [
#           "ssm:GetParametersByPath",
#           "ssm:GetParameters",
#           "ssm:GetParameter",
#           "ssm:ListInventoryEntries",
#           "ssm:ListCommands",
#           "ssm:DescribeParameters"
#         ],
#         "Resource" : "arn:aws:ssm:eu-west-2:895581202168:parameter/blog-app/*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "test_policy4" {
#   name = "test_policy4"
#   role = aws_iam_role.test_role.id

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Sid" : "VisualEditor0",
#         "Effect" : "Allow",
#         "Action" : [
#           "s3:PutObject",
#           "s3:GetObject"
#         ],
#         "Resource" : "arn:aws:s3:::myaws3-buk/uploads/*"
#       }
#     ]
#   })
# }

# ////////////////instance profile creation to attach the above role to the autoscaling group instances\\\\\\

# resource "aws_iam_instance_profile" "blogapp_instance_profile" {
#   name = "blogapp_instance_profile"
#   role = aws_iam_role.test_role.name
# }


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
          Service = "ec2.amazonaws.com"
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
