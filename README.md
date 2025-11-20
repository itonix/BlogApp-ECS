BlogApp-ECS project is an ECS docker containerized  implimentation of earlier project in ec2-ASG-Autoscaling group.This project uses Terraform to provision and dismantle resources it creates.

Jenkins is used here as the CICD tool.


****1.Project Documentation****
----------------------

Project Overview

## This project provisions a highly available, secure, and scalable AWS infrastructure for a Blog Application using Terraform. The stack includes:

## Networking: VPC, Public and Private Subnets, Internet Gateway, NAT Gateway, Route Tables.

## Security: Security Groups for VPC, EC2, RDS; Ingress/Egress rules.

## Compute: ECS Cluster on EC2 with Auto Scaling group self managed

## Containers: ECS Task Definition with Docker container from Docker Hub (docker image is generated via jenkins pipeline and pushed based on build stage only in 'BUILD' step.

## Load Balancing: ALB (HTTPS with ACM certificate), Target Groups, Listeners, Redirection. : Domain Just4study.click

## Database: RDS MariaDB with private subnets.

## Storage: S3 bucket with CORS and server-side encryption. 

## CI/CD / Automation: Terraform for provisioning and AWS Lambda for sending welcome emails using S3 + SES.

## Secrets Management: Parameters in AWS SSM Parameter Store.

## ALB to CLOUDFLARE DNS: Optional Cloudflare integration for DNS.


#################
#Orchestration :
CICD : Jenkins pipleline ,please reference the `Jenkinsfile`
IaC : Terraform (backend configured to TF cloud)

################

Terraform Components:

#Component	Resource Type	Purpose

| Component           | Resource Type             | Purpose                                          |
| ------------------- | ------------------------- | ------------------------------------------------ |
| VPC                 | `aws_vpc`                 | Network isolation with DNS support               |
| Subnets             | `aws_subnet`              | Public for ALB/NAT, Private for EC2/RDS          |
| Internet Gateway    | `aws_internet_gateway`    | Public internet access                           |
| NAT Gateway         | `aws_nat_gateway`         | Private subnet outbound internet access          |
| Route Tables        | `aws_route_table`         | Public & private routing                         |
| Security Groups     | `aws_security_group`      | Control inbound/outbound traffic                 |
| ECS Cluster         | `aws_ecs_cluster`         | Manage containerized applications                |
| Launch Template     | `aws_launch_template`     | EC2 configuration for ECS                        |
| Auto Scaling Group  | `aws_autoscaling_group`   | Dynamic EC2 scaling                              |
| ECS Task Definition | `aws_ecs_task_definition` | Container specs (CPU, memory, ports, secrets)    |
| ECS Service         | `aws_ecs_service`         | Runs tasks on cluster with load balancer         |
| Load Balancer       | `aws_lb`                  | Public facing ALB with HTTPS                     |
| Target Group        | `aws_lb_target_group`     | Connects ALB to ECS tasks                        |
| Listeners           | `aws_lb_listener`         | HTTP → HTTPS redirect & HTTPS traffic to targets |
| RDS Database        | `module "db"`             | Private MariaDB instance                         |
| S3 Bucket           | `aws_s3_bucket`           | Stores blog images & Lambda artifacts            |
| Lambda              | `aws_lambda_function`     | Sends welcome emails via SES & S3                |
| IAM Roles           | `aws_iam_role` + `module` | Task roles, instance profiles, Lambda execution  |


includes directly attaching ssm paramaters and ses connectivity SES take 24 hours for activation and identity verifcation so pre configured to avoid delay

##########

#ECS Blog App Flow

User Request → Domain(cloudflare)--->Hits ALB (HTTPS) → Forwarded to ECS container instance in private subnet Task via Target Group.

ECS Task → Runs Docker container (tonygeorgethomas/blog_app:latest) → Handles request.

Container Secrets → Provided via SSM Parameter Store.

Database Access → Private RDS MariaDB instance.

Static Assets / Uploads → Stored in S3 (with proper bucket policy & CORS).

Welcome Email for user signup → Lambda triggered by events in S3 → Sends email via SES.

Auto Scaling → EC2 instances scale up/down using ASG and ECS Capacity Provider.

#########                                                                                            ####
              <img width="445" height="636" alt="image" src="https://github.com/user-attachments/assets/9b07a270-73f0-4c13-a5e4-01a042372e76" />

       #########################################################                                           

TF clould is given a federated role  `Securely access AWS from HCP Terraform using OIDC federation` .TF cloud uses env varibles like : 
<img width="1056" height="407" alt="image" src="https://github.com/user-attachments/assets/0922d864-4b17-420c-bc9f-792bbd166542" />


<img width="1271" height="552" alt="resoursemap" src="https://github.com/user-attachments/assets/d93705b2-8917-48f9-be43-dfa8b97f0fcf" />

<img width="1677" height="363" alt="spreadplacementstrategy" src="https://github.com/user-attachments/assets/dc105484-6261-4820-b09a-7993b90c256a" />

