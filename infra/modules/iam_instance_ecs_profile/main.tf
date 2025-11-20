resource "aws_iam_role" "instance_ecs_role" {
  name = "my-ecstemplateRole"

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

# Attach the correct managed policy for ECS EC2 instances
resource "aws_iam_role_policy_attachment" "instance_role_attachment" {
  role       = aws_iam_role.instance_ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance_ecs_profile" {
  name = "myecsInstanceRole"
  role = aws_iam_role.instance_ecs_role.name
}
