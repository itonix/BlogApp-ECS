output "launch_template_id" {
  value = aws_launch_template.ecslaunch_template.id

}

output "launch_template_version" {
  value = aws_launch_template.ecslaunch_template.latest_version

}