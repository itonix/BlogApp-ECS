
resource "aws_ecs_task_definition" "blog_app_task" {
  family                   = "service"
  requires_compatibilities = ["EC2"]
  network_mode             = var.network_mode
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn
  cpu                      = var.cpu
  memory                   = var.memory
  container_definitions = jsonencode([
    {
      name      = "blog_app_container"
      image     = var.blog_image_uri #using public repo
      cpu       = 128
      memory    = 128
      essential = true
      portMappings = [
        {
          containerPort = 3001
          hostPort      = 0 #host port 0 means dynamic port mapping since using bridge mode
          protocol      = "tcp"
        }
      ]
      secrets = var.secrets

    }
  ])
}

