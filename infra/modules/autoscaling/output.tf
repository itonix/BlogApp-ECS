


output "autoscaling_group_name" {
  value = aws_autoscaling_group.ecs-autoscaling-group.name
}
output "auto_scaling_group_arn" {
  value = aws_autoscaling_group.ecs-autoscaling-group.arn

}