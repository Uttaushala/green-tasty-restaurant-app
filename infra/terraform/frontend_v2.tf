# --- Frontend v2 stand: a second, independent S3 + CloudFront pair for the rewritten frontend.
# The original stand (s3.tf / cloudfront.tf) is untouched and keeps serving the live site.
# These resources were first created by hand with the AWS CLI and are adopted via
# `terraform import` (see the commands in the PR/commit description), so no downtime and no recreation.
# Switching production to v2 later = repointing the origin of aws_cloudfront_distribution.frontend
# (or swapping domains); rolling back = the reverse. ---

resource "aws_s3_bucket" "frontend_v2" {
  bucket = "restaurant-frontend-v2-${var.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_v2" {
  bucket = aws_s3_bucket.frontend_v2.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_v2" {
  bucket                  = aws_s3_bucket.frontend_v2.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "frontend_v2" {
  bucket = aws_s3_bucket.frontend_v2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontV2"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_v2.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend_v2.arn
          }
        }
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend_v2]
}

resource "aws_cloudfront_distribution" "frontend_v2" {
  comment             = "restaurant-frontend v2"
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.frontend_v2.bucket_regional_domain_name
    origin_id                = "s3-v2"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id # shared with the original stand
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-v2"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS managed: CachingOptimized
  }

  # Angular SPA client-side routing: any path S3 can't resolve gets index.html.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cloudfront_v2_distribution_domain_name" {
  value = aws_cloudfront_distribution.frontend_v2.domain_name
}

output "cloudfront_v2_distribution_id" {
  value = aws_cloudfront_distribution.frontend_v2.id
}
