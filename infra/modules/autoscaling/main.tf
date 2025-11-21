

//////////////////////////////////////////


resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name                      = "ecs-autoscaling-group"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  force_delete              = false
  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  vpc_zone_identifier = var.vpc_zone_identifier

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }


  timeouts {
    delete = "3m"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}



