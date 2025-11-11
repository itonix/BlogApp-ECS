

# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Name = "Blog_AppInfra_${terraform.workspace}"
    }

  }
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
  count                   = length(local.azs)
  cidr_block              = cidrsubnet(aws_vpc.blog_vpc.cidr_block, 12, count.index)
  map_public_ip_on_launch = "true"
  availability_zone       = local.azs[count.index]

  tags = {
    Name        = "my-pubsub${count.index + 1}"
    environment = "development"
  }
}


# # create subnet private
# resource "aws_subnet" "my-privsub-1" {
#   vpc_id     = aws_vpc.blog_vpc.id
#   cidr_block = "10.0.1.0/26"
#   map_public_ip_on_launch = "false"
#   availability_zone = "eu-west-2a"

#   tags = {
#     Name = "my-privsub1"
#   }
# }

#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.blog_vpc.id

  tags = {
    Name = "my-gateway"
  }
}


#create route and route table :

resource "aws_route_table" "myroute" {
  vpc_id = aws_vpc.blog_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-route"
  }
}

# create route table association

resource "aws_route_table_association" "subnetassociation" {
  count          = length(aws_subnet.publicsubnets)
  subnet_id      = aws_subnet.publicsubnets[count.index].id
  route_table_id = aws_route_table.myroute.id
}



#create sec group for VPC- ---#

##################################################################
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

# Egress: allow ALL outbound traffic to internet

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.vpc_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



########################################################################

#create sec group for EC2 instances- ---#


##################################################################
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



# Egress: allow ALL outbound traffic to internet
resource "aws_vpc_security_group_egress_rule" "ec2allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ec2_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}





########################################################################

#security group for RDS
resource "aws_security_group" "rds_securitygrp" {
  name        = "rds_securitygrp"
  description = "Allow http/ssh from VPC SG and all outbound"
  vpc_id      = aws_vpc.blog_vpc.id

  tags = {
    Name = "rds_securitygrp"
  }
}

# Ingress: allow ec2 access from aws_security_group.ec2_securitygrp.id
resource "aws_vpc_security_group_ingress_rule" "rds_securitygrp_ec2allow" {
  security_group_id            = aws_security_group.rds_securitygrp.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2_securitygrp.id
}



# Egress: allow ALL outbound traffic to internet
resource "aws_vpc_security_group_egress_rule" "rds_egress_rule" {
  security_group_id = aws_security_group.rds_securitygrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

}

########################################################################



//--------------------------------------------//
# to get the free tier image of Amzaon 2023 linux X86_64
data "aws_ami" "testimage" {
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "free-tier-eligible"
    values = ["true"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


#########################################################launc template for autoscaling group#####
resource "aws_launch_template" "my_launch_template" {
  name = "my-launch-template"

  image_id = data.aws_ami.testimage.id
  iam_instance_profile {
    //name = "EC2App-test"
    name = module.iam.instance_profile_name #custom iam instance profile from iam module
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
      Name = "my-Ec2launch-template-instances"
    }
  }

  user_data = filebase64("${path.module}/script.sh")
}



# Generate a TLS private key

# resource "tls_private_key" "my_blogapp_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096


# }


# #Save the private key locally

# resource "local_sensitive_file" "my_blogapp_pem" {
#   content  = tls_private_key.my_blogapp_key.private_key_pem
#   filename = "mykey-${terraform.workspace}.pem"

#   # Ensure the file is only written after key creation
#   depends_on = [tls_private_key.my_blogapp_key]
# }


# # #####################################################Create AWS key pair using the public key

# resource "aws_key_pair" "deployer_key" {
#   key_name   = "mykey-${terraform.workspace}-key"
#   public_key = tls_private_key.my_blogapp_key.public_key_openssh

#   lifecycle {
#     ignore_changes = [key_name] # key name is immutable
#   }
#   # Ensure key pair is created only after private key exists
#   depends_on = [tls_private_key.my_blogapp_key]
# }


#we will use an existing key pair for simplicity
data "aws_key_pair" "deployer_key" {
  key_name = "london"
}



# ###########################################################Create EC2 instance#####################
# # create instance App server
# resource "aws_instance" "app_server" {
#   ami           = data.aws_ami.testimage.id
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.publicsubnets[0].id
#   key_name = data.aws_key_pair.deployer_key.key_name
#   associate_public_ip_address = true
#   vpc_security_group_ids = [aws_security_group.vpc_securitygrp.id]
#   tags = {
#     Name = "tf-example"
#   }
# }

# resource "aws_instance" "jenkins_server" {
#   ami           = data.aws_ami.testimage.id
#   instance_type = "t2.micro"
#   subnet_id     = aws_subnet.publicsubnets[1].id
#   key_name = data.aws_key_pair.deployer_key.key_name
#   associate_public_ip_address = true
#   vpc_security_group_ids = [aws_security_group.vpc_securitygrp.id]
#   tags = {
#     Name = "tf-example"
#   }
# }



##########################################################Auto scaling group module

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.1"
  # insert the 1 required variable here
  name            = "MyBlogApp-ASG"
  use_name_prefix = true
  # and any of the optional variables you want here   
  min_size                  = 2
  max_size                  = 3
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300 #seconds
  vpc_zone_identifier       = aws_subnet.publicsubnets[*].id
  # Launch template
  launch_template_id     = aws_launch_template.my_launch_template.id
  instance_type          = "t2.micro"
  instance_name          = "asg-instances"
  create_launch_template = false
  depends_on             = [aws_launch_template.my_launch_template]
  tags = {
    Environment         = terraform.workspace
    Project             = "megasecret"
    propagate_at_launch = true
  }


}


############################################################ setting for load balancer- application load balancer
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
# Create a target group for the load balancer
resource "aws_lb_target_group" "blogapp_tg" {
  name     = "blogapp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.blog_vpc.id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600 # 1 hour
    enabled         = true
  }

  health_check {
    path                = "/system/health"
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
///////////////////////////////////////////////////




###http to https redirection listener

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



# Attach the Auto Scaling Group to the Target Group
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = module.autoscaling.autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.blogapp_tg.arn
}


#######################ssm parameter store to store DB endpoint##
data "aws_ssm_parameter" "db_user" {
  name = "/blog-app/DB_USER"
}

data "aws_ssm_parameter" "db_pass" {
  name = "/blog-app/DB_PASS"
}



#################################################################Create rds mariadb instance###
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
  publicly_accessible         = true
  db_name                     = "blogdb"
  username                    = data.aws_ssm_parameter.db_user.value
  port                        = "3306"
  availability_zone           = local.azs[0]
  # subnet ids for the RDS instance
  create_db_subnet_group  = true
  subnet_ids              = aws_subnet.publicsubnets[*].id
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



# # #create ################################     S3bucket for storing blog images  #######
resource "aws_s3_bucket" "blog_app_bucket" {
  bucket = var.s3_bucket_name
  tags = {
    Name        = "Blog App Bucket"
    Environment = terraform.workspace
  }
}

#bucket encryption using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "blogapp_encryption" {
  bucket = aws_s3_bucket.blog_app_bucket.id

  rule {
    bucket_key_enabled = true
  }
}


###test s3
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




# CORS configuration to allow cross-origin requests

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


################################################################################################## Lambda function to send welcome email using SES and S3
# create lambda function and ses & s3 fetch
# :my-wemail-template bucket is assuemd to be present and has the email template files stored in it. 

# IAM role for Lambda execution
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


# Attach the AWSLambdaBasicExecutionRole policy to the role
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

# Lambda function
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


# ####################################lambda ends##########################


#### ACM certificate for just4study.click###
data "aws_acm_certificate" "cert" {
  domain      = "*.just4study.click" # Must match the certificate domain
  statuses    = ["ISSUED"]
  most_recent = true
  types       = ["IMPORTED"] # Because your cert is imported
  # optional region override if needed
  # provider = aws.eu_west_2
}


# ### Attach the certificate to the ALB listener
# resource "aws_lb_listener_certificate" "myssl_cert" {
#   listener_arn    = aws_lb_listener.app_listener.arn
#   certificate_arn = data.aws_acm_certificate.cert.arn
# }
#########################cloudflare provider module##########################

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID for just4study.click"
}


module "cloudflare" {
  source             = "./modules/cloudflare"
  alb_dns_name       = aws_lb.frontend_lb.dns_name
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "iam" {
  source      = "./modules/iam"
  custom_role = "blogapp_role"
}  