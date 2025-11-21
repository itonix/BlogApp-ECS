


resource "aws_ecs_service" "blog_app_service" {
  name                               = var.name
  cluster                            = var.clustername
  force_new_deployment               = true
  force_delete                       = true
  task_definition                    = var.task_definition_arn
  desired_count                      = var.desired_count
  scheduling_strategy                = var.scheduling_strategy
  deployment_minimum_healthy_percent = 0
  health_check_grace_period_seconds  = 60
  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 100
  }
  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }


  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }


}
