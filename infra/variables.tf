variable "mypulicsubname" {
  description = "The name of the public subnet"
  type        = list(string)
  default     = ["public_subnet1", "public_subnet2", "public_subnet3"]

}

variable "myprivatesubname" {
  description = "The name of the private subnet"
  type        = list(string)
  default     = ["private_subnet1", "private_subnet2", "private_subnet3"]

}

variable "region" {
  type = string

}

variable "mykeyname" {
  description = "The name of the key pair"
  type        = string
  default     = "london"


}


variable "welcomemail_artifactbucket" {
  description = "The name of the S3 bucket for welcome mail template"
  type        = string
  default     = "my-wemail-template"

}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "myaws3-buk"

}

variable "principle_arn" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "arn:aws:iam::895581202168:user/Appuser"
}

variable "custom_role" {
  description = "The name of the custom IAM role"
  type        = string
  default     = ""
}

variable "ses_identities" {
  default = [
    "arn:aws:ses:eu-west-2:895581202168:identity/just4study.click",
    "arn:aws:ses:eu-west-2:895581202168:configuration-set/my-first-configuration-set",
    "arn:aws:ses:eu-west-2:895581202168:identity/tonyshery@gmail.com"
  ]
}


variable "myrepo" {
  description = "ECR public repository name"
  type        = string
  default     = "tonygeorgethomas/blog_app:latest"
}


variable "replica_count"{
  description = "No of containers to run"
  type = number
  default = 2
}