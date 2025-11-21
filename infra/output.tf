


output "lb_dns" {
  value = aws_lb.frontend_lb.dns_name
}


# output "s3_bucket_name" {
#   value = aws_s3_bucket.blog_app_bucket.bucket
# }


# output "asg_name" {
#   value = module.autoscaling.autoscaling_group_name
# }

output "frontend_lb_dns_name4cloudflare" {
  value = aws_lb.frontend_lb.dns_name
}


output "frontend_lb_dns" {
  value = "http://${aws_lb.frontend_lb.dns_name}"

}