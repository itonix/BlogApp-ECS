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
