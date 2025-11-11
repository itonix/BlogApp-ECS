output "instance_profile_name" {
  description = "IAM instance profile name for BlogApp"
  value       = aws_iam_instance_profile.blogapp_instance_profile.name
}

output "role_arn" {
  description = "ARN of the IAM role used for BlogApp EC2 instances"
  value       = aws_iam_role.blogapp_role.arn
}
