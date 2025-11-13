

# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Name = "Blog_AppInfra_${terraform.workspace}"
    }

  }
}



# Additional provider for ECR Public (in us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}




data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

output "identities" {
  value = data.aws_caller_identity.current

}

# #creating a random id
# resource "random_id" "random" {
#   byte_length = 8
# }

#create A vpc
resource "aws_vpc" "blog_vpc" {
  cidr_block           = "10.0.0.0/16"
  region               = data.aws_region.current.id
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "blog_vpc"
  }
}

# Retrieve the list of availability zones in the current AWS region
data "aws_availability_zones" "myzones" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.myzones.names, 0, 3)
}

output "Az" {
  value = local.azs
}


# create subnet public
resource "aws_subnet" "publicsubnets" {

  vpc_id                  = aws_vpc.blog_vpc.id
  count                   = length(local.azs) - 1
  cidr_block              = cidrsubnet(aws_vpc.blog_vpc.cidr_block, 7, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = local.azs[count.index]

  tags = {
    Name        = "publicsubnet-${count.index + 1}"
    environment = "development"
  }
}

output "publicsub" {
  value = aws_subnet.publicsubnets[*].id
}

# create subnet private
resource "aws_subnet" "privatesubnets" {
  vpc_id                  = aws_vpc.blog_vpc.id
  count                   = length(local.azs)
  cidr_block              = cidrsubnet(aws_vpc.blog_vpc.cidr_block, 7, 8 + count.index)
  map_public_ip_on_launch = "false"
  availability_zone       = local.azs[count.index]

  tags = {
    Name        = "privatesubnet-${count.index + 1}"
    environment = "development"
  }
}


output "privatesub" {
  value = aws_subnet.privatesubnets[*].id
}

#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.blog_vpc.id

  tags = {
    Name = "my-gateway"
  }
}



#create route and route table :

resource "aws_route_table" "route_public" {
  vpc_id = aws_vpc.blog_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-route-public"
  }
}


#####NAT Gateway elatic ip##########
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# ###########create nat gateway##########
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.publicsubnets[0].id

  tags = {
    Name = "nat-gateway"
  }
  depends_on = [aws_internet_gateway.gw]
}




################ private route table and route ###########
resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.blog_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }


  tags = {
    Name = "private-route-table"
  }
}





# # # create route table association

resource "aws_route_table_association" "publicsubnetassociation" {
  count          = length(aws_subnet.publicsubnets)
  subnet_id      = aws_subnet.publicsubnets[count.index].id
  route_table_id = aws_route_table.route_public.id
}


resource "aws_route_table_association" "privatesubnetassociation" {
  count          = length(aws_subnet.privatesubnets)
  subnet_id      = aws_subnet.privatesubnets[count.index].id
  route_table_id = aws_route_table.private-route.id
}



# #create sec group for VPC- ---#

# ##################################################################
resource "aws_security_group" "vpc_securitygrp" {
  name        = "vpc_securitygrp"
  description = "Allow ssh inbound traffic and  outbound traffic"
  vpc_id      = aws_vpc.blog_vpc.id

  tags = {
    Name = "vpc_securitygrp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.vpc_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.vpc_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}



resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.vpc_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


# # Egress: allow ALL outbound traffic to internet

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.vpc_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



# ########################################################################

# #create sec group for EC2 instances- ---#


# ##################################################################
resource "aws_security_group" "ec2_securitygrp" {
  name        = "ec2_securitygrp"
  description = "Allow http/ssh from VPC SG and all outbound"
  vpc_id      = aws_vpc.blog_vpc.id

  tags = {
    Name = "ec2_securitygrp"
  }
}

# Ingress: allow HTTP from VPC SG
resource "aws_vpc_security_group_ingress_rule" "ec2allow_httpforALB" {
  security_group_id            = aws_security_group.ec2_securitygrp.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_securitygrp.id
}
resource "aws_vpc_security_group_ingress_rule" "ec2allow_http" {
  security_group_id = aws_security_group.ec2_securitygrp.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# Ingress: allow SSH from VPC SG
resource "aws_vpc_security_group_ingress_rule" "ec2allow_sshfromALB" {
  security_group_id            = aws_security_group.ec2_securitygrp.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpc_securitygrp.id
}



# # Egress: allow ALL outbound traffic to internet
resource "aws_vpc_security_group_egress_rule" "ec2allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ec2_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}





# ########################################################################

#security group for RDS
resource "aws_security_group" "rds_securitygrp" {
  name        = "rds_securitygrp"
  description = "Allow http/ssh from VPC SG and all outbound"
  vpc_id      = aws_vpc.blog_vpc.id

  tags = {
    Name = "rds_securitygrp"
  }
}

# # Ingress: allow ec2 access from aws_security_group.ec2_securitygrp.id
resource "aws_vpc_security_group_ingress_rule" "rds_securitygrp_ec2allow" {
  security_group_id            = aws_security_group.rds_securitygrp.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2_securitygrp.id
}



# # Egress: allow ALL outbound traffic to internet
resource "aws_vpc_security_group_egress_rule" "rds_egress_rule" {
  security_group_id = aws_security_group.rds_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}


###################query ssm to get recommnde ami for ecs optimized amazon linux 2023

data "aws_ssm_parameter" "ecs_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

output "ecs_ami_id" {
  value     = data.aws_ssm_parameter.ecs_ami_id.value
  sensitive = true
}

####
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ECS-Cluster"

}

# # #########################################################launc template for autoscaling group#####

#import existing iam instance profile
data "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceRole"
}




resource "aws_launch_template" "ecslaunch_template" {
  name = "ecslaunch-template"

  image_id = data.aws_ssm_parameter.ecs_ami_id.value
  iam_instance_profile {
    //name = "EC2App-test"
    name = data.aws_iam_instance_profile.ecs_instance_profile.name
  }
  instance_initiated_shutdown_behavior = "terminate"
  vpc_security_group_ids               = [aws_security_group.ec2_securitygrp.id] # <- use this
  instance_type                        = "t2.micro"
  key_name                             = data.aws_key_pair.deployer_key.key_name

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
                echo ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true >> /etc/ecs/ecs.config
                echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config
                EOF
  )
}




# # # #####################Create AWS key pair using the public key

#we will use an existing key pair for simplicity
data "aws_key_pair" "deployer_key" {
  key_name = "london"
}






# # ##########################################################Auto scaling group module

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.1"
  # insert the 1 required variable here
  name            = "ecs-autoscaling-group"
  use_name_prefix = true
  # and any of the optional variables you want here   
  min_size                  = 1
  max_size                  = 2
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300 #seconds
  vpc_zone_identifier       = aws_subnet.privatesubnets[*].id
  # Launch template
  launch_template_id      = aws_launch_template.ecslaunch_template.id
  launch_template_version = "$Latest"
  instance_type           = "t2.micro"
  instance_name           = "asg-instances"
  create_launch_template  = false
  depends_on              = [aws_launch_template.ecslaunch_template]
  # tags = {
  #   Environment         = terraform.workspace
  #   Project             = "megasecret"
  #   propagate_at_launch = true
  # }
  tags = {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
  autoscaling_group_tags = {
    key                 = "Environment"
    value               = terraform.workspace
    propagate_at_launch = true
  }

}

output "autoscaling_group_name" {
  value = module.autoscaling.autoscaling_group_name
}


////ecs capacity provider///
resource "aws_ecs_capacity_provider" "my_capacity_provider" {
  name = "my_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
    }
  }

  tags = {
    Project = "ecs-capacity-provider"
  }
}

###################aws_ecs_cluster_capacity_providers###
resource "aws_ecs_cluster_capacity_providers" "blog_ecs_cluster_capacity" {
  cluster_name = local.ecs_cluster_name

  capacity_providers = [
    aws_ecs_capacity_provider.my_capacity_provider.name,
  ]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.my_capacity_provider.name
  }
}


##### pull public container from ECR repository######

locals {
  blog_image_uri = "public.ecr.aws/w7l2n4u3/itonix/blog_app:latest"
}


resource "aws_ecs_task_definition" "blog_app_task" {
  family                   = "service"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  task_role_arn            = module.iam.role_arn
  execution_role_arn       = module.iam.role_arn
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([
    {
      name      = "blog_app_container"
      image     = local.blog_image_uri #using public repo
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3001
          hostPort      = 0 #host port 0 means dynamic port mapping since using bridge mode
          protocol      = "tcp"
        }
      ]
      secrets = [
        {
          name      = "DB_USER"
          valueFrom = "/blog-app/DB_USER"
        },
        {
          name      = "DB_PASS"
          valueFrom = "/blog-app/DB_PASS"
        },
        {
          name      = "DB_HOST"
          valueFrom = "/blog-app/DB_HOST"
        },
        {
          name      = "S3_BUCKET_NAME"
          valueFrom = "/blog-app/S3_BUCKET_NAME"
          }, {
          name      = "DB_NAME"
          valueFrom = "/blog-app/DB_NAME"
        },
        {
          name      = "AWS_REGION"
          valueFrom = "/blog-app/AWS_REGION"
        },
        {
          name      = "DB_PORT"
          valueFrom = "/blog-app/DB_PORT"
        },
        {
          name      = "S3_BUCKET_NAME_TEMPLATE"
          valueFrom = "/blog-app/S3_BUCKET_NAME_TEMPLATE"
        },
        {
          name      = "S3_BUCKET_REGION"
          valueFrom = "/blog-app/S3_BUCKET_REGION"
        },
      ]
    }
  ])
}




############################ecs service role for alb##########################

locals {
  ecs_service_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS"
}


############################ ecs service creation ##########################




resource "aws_ecs_service" "blog_app_service" {
  name                = "app-service"
  cluster             = local.cluster_id
  task_definition     = aws_ecs_task_definition.blog_app_task.arn
  desired_count       = 2
  scheduling_strategy = "REPLICA"
  iam_role            = local.ecs_service_role_arn

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blogapp_tg.arn
    container_name   = "blog_app_container"
    container_port   = 3001
  }
  depends_on = [aws_lb_target_group.blogapp_tg
    ,
    aws_ecs_cluster_capacity_providers.blog_ecs_cluster_capacity
  ]


}

/////////////////////////////////ECS-cluster creation##########################


module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  name                    = "ecs-ec2"
  create_task_exec_policy = false
  configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/aws-ec2"
      }
    }
  }


  tags = {
    Environment = "Development"
    Project     = "EcsEc2"
  }
}


###########################################
locals {
  ecs_cluster_name = module.ecs_cluster.name
}

locals  {

  cluster_id = module.ecs_cluster.id
}






# # ############################################################ setting for load balancer- application load balancer
resource "aws_lb" "frontend_lb" {
  name               = "frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vpc_securitygrp.id]
  subnets            = aws_subnet.publicsubnets[*].id

  tags = {
    Name        = "frontend-lb"
    Environment = terraform.workspace
  }
}
# # Create a target group for the load balancer
resource "aws_lb_target_group" "blogapp_tg" {
  name     = "blogapp-tg"
  port     = 3001 #container port
  protocol = "HTTP"
  vpc_id   = aws_vpc.blog_vpc.id
  # stickiness {
  #   type            = "lb_cookie"
  #   cookie_duration = 3600 # 1 hour
  #   enabled         = true
  # }

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "blogapp-tg"
    Environment = terraform.workspace
  }
}
# # # ///////////////////////////////////////////////////




# # # ###http to https redirection listener

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.frontend_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}



resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.frontend_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blogapp_tg.arn
  }
}



# # Attach the Auto Scaling Group to the Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = module.autoscaling.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.blogapp_tg.arn
}


# # #######################ssm parameter store to store DB endpoint##
data "aws_ssm_parameter" "db_user" {
  name = "/blog-app/DB_USER"
}

data "aws_ssm_parameter" "db_pass" {
  name = "/blog-app/DB_PASS"
}




# # #################################################################Create rds mariadb instance###
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier                  = "blog-db-instance"
  create_db_option_group      = false
  create_db_parameter_group   = false
  create_db_instance          = true
  create_monitoring_role      = false
  database_insights_mode      = "standard"
  manage_master_user_password = false
  engine                      = "mariadb"
  engine_version              = "11.4.5"
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  storage_type                = "gp2"
  multi_az                    = false
  publicly_accessible         = false
  db_name                     = "blogdb"
  username                    = data.aws_ssm_parameter.db_user.value
  port                        = "3306"
  availability_zone           = local.azs[0]
  # subnet ids for the RDS instance
  create_db_subnet_group  = true
  subnet_ids              = aws_subnet.privatesubnets[*].id
  password                = data.aws_ssm_parameter.db_pass.value # ideally, use secrets manager or SSM parameter store to fetch this value
  skip_final_snapshot     = true
  backup_retention_period = 0
  vpc_security_group_ids  = [aws_security_group.rds_securitygrp.id]
  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  tags = {
    Owner       = "user"
    Environment = terraform.workspace
  }

}



# # # # #create ################################     S3bucket for storing blog images  #######
resource "aws_s3_bucket" "blog_app_bucket" {
  bucket = var.s3_bucket_name
  tags = {
    Name        = "Blog App Bucket"
    Environment = terraform.workspace
  }
}

# #bucket encryption using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "blogapp_encryption" {
  bucket = aws_s3_bucket.blog_app_bucket.id

  rule {
    bucket_key_enabled = true
  }
}


# # ###test s3
resource "aws_s3_bucket_policy" "blog_app_bucket_policy" {
  bucket     = aws_s3_bucket.blog_app_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.blogapp_public_access]
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowIAMUserAccess",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${var.principle_arn}" },
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Resource" : "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        "Sid" : "PublicReadUploads",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["s3:GetObject"],
        "Resource" : "arn:aws:s3:::${var.s3_bucket_name}/uploads/*"
      }
    ]
  })
}




# # # CORS configuration to allow cross-origin requests

resource "aws_s3_bucket_cors_configuration" "blogapp_cors" {
  bucket = aws_s3_bucket.blog_app_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_ownership_controls" "blogapp_ownership" {
  bucket = aws_s3_bucket.blog_app_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "blogapp_public_access" {
  bucket = aws_s3_bucket.blog_app_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# # ################################################################################################## Lambda function to send welcome email using SES and S3
# # # create lambda function and ses & s3 fetch
# # # :my-wemail-template bucket is assuemd to be present and has the email template files stored in it. 

# # IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda4_s3sesrole" {
  name               = "lambda4_s3sesrole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_ses_policy"
  role = aws_iam_role.lambda4_s3sesrole.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.welcomemail_artifactbucket}/*",
        "Sid" : "Statement1"
      },
      {
        "Action" : [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "ses:SendTemplatedEmail"
        ],
        "Effect" : "Allow",
        "Resource" : var.ses_identities,
        "Sid" : "Statement2"
      }
    ]
  })
}


# # # Attach the AWSLambdaBasicExecutionRole policy to the role
resource "aws_iam_role_policy_attachment" "basicexecution" {
  role       = aws_iam_role.lambda4_s3sesrole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# Package the Lambda function code
data "archive_file" "ziparchive4lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/welcomefunction.zip"
}

# # Lambda function
resource "aws_lambda_function" "welcomefunction" {
  filename         = data.archive_file.ziparchive4lambda.output_path
  function_name    = "welcomefunction"
  role             = aws_iam_role.lambda4_s3sesrole.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.ziparchive4lambda.output_base64sha256

  runtime = "nodejs20.x"

  tags = {
    Environment = "production"
    Application = "blogapp"
  }
}


# # # ####################################lambda ends##########################


# # #### ACM certificate for just4study.click###
data "aws_acm_certificate" "cert" {
  domain      = "*.just4study.click" # Must match the certificate domain
  statuses    = ["ISSUED"]
  most_recent = true
  types       = ["IMPORTED"] # Because your cert is imported
  # optional region override if needed
  # provider = aws.eu_west_2
}


# # ### Attach the certificate to the ALB listener
resource "aws_lb_listener_certificate" "myssl_cert" {
  listener_arn    = aws_lb_listener.app_listener.arn
  certificate_arn = data.aws_acm_certificate.cert.arn
}
# # #########################cloudflare provider module##########################

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID for just4study.click"
}


module "cloudflare" {
  source             = "./modules/cloudflare"
  alb_dns_name       = aws_lb.frontend_lb.dns_name
  cloudflare_zone_id = var.cloudflare_zone_id #in tf cloud as env variable TF_VAR_cloudflare_zone_id
}


### role for task execution and task role for ecs service and task definition  

module "iam" {
  source      = "./modules/iam"
  custom_role = "blogapp_role"
}






