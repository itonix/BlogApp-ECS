# Output the Role ARN
output "ecstaskexecution_role_arn" {
  value = aws_iam_role.ecstaskexecution_role.arn
}
output "ecstaskexecution_role_name" {
  value = aws_iam_role.ecstaskexecution_role.name
}