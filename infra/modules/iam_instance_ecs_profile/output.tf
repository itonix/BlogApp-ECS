

########-------instance profile########

output "instanceprofile_name" {
  value = aws_iam_instance_profile.instance_ecs_profile.name

}

output "instanceprofile_arn" {
  value = aws_iam_instance_profile.instance_ecs_profile.arn

}

###--------------ecs role------------------####

output "ecsec2role_name" {
  value = aws_iam_role.instance_ecs_role.name

}

output "ecsec2role_arn" {
  value = aws_iam_role.instance_ecs_role.arn
}
