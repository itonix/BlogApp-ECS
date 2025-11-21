output "mytaskdef_arn" {
  value = aws_ecs_task_definition.blog_app_task.arn

}

output "mytaskdef_name" {
  value = aws_ecs_task_definition.blog_app_task.id

}