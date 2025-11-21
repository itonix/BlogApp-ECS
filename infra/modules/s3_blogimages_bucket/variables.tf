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
