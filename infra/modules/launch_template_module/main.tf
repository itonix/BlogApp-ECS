resource "aws_launch_template" "ecslaunch_template" {
  name = var.name

  image_id = var.imageid
  iam_instance_profile {
    //name = "EC2App-test"
    name = var.iaminstanceprofile_name
  }
  instance_initiated_shutdown_behavior = "terminate"
  vpc_security_group_ids               = var.vpcsecuritygroupids # <- use this
  instance_type                        = var.instancetype
  key_name                             = var.keynameto_use

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ecs-ec2-instance"
    }
  }

  user_data = base64encode(<<-EOF
                #!/bin/bash
                systemctl enable docker
                systemctl start docker
                echo ECS_CLUSTER=${var.clustername} > /etc/ecs/ecs.config
                echo ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true >> /etc/ecs/ecs.config
                echo ECS_WARM_POOLS_CHECK=true >> /etc/ecs/ecs.config
                EOF
  )
  # <<< ensures cluster exists first
}
