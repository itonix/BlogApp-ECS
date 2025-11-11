terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.12.0"
    }
  }
}

# Minimal provider declaration

variable "alb_dns_name" {
  type = string
}



variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID for just4study.click"
}







# Create CNAME record
resource "cloudflare_dns_record" "just4study_dns_record" {
  zone_id = var.cloudflare_zone_id
  name    = "just4study.click"
  type    = "CNAME"
  ttl     = 1
  content = var.alb_dns_name
  proxied = true
  comment = "Set ALB DNS record"
}
