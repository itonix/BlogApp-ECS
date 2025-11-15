
output "taskrole_name" {
  value = aws_iam_role.blogapp_task_role.name

}

output "taskrole_arn" {
  value = aws_iam_role.blogapp_task_role.arn
}
