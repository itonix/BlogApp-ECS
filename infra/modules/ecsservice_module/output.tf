output "blog_app_service_name" {
  value = aws_ecs_service.blog_app_service.name

}
output "blog_app_service_arn" {
  value = aws_ecs_service.blog_app_service.arn

}

