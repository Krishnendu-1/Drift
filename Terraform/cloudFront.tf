resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.website_bucket_name}-oac"
  description                       = "OAC allowing CloudFront to read private S3 website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "This is cresting the edge cache endpoint"
  price_class         = "PriceClass_200" # Includes India, Asia, Europe, and North America to control over the data transfer price. if not given then terraform automatically assign price_class="ALL"

  origin {
    #* IMPORTANT: OAC requires bucket_regional_domain_name (REST endpoint), NOT website_endpoint
    domain_name              = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS", "PUT", "POST", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # AWS Managed Cache Policy: CachingOptimized (ID is universal across all AWS accounts), can be found in documentation. Or i can also create some policy by my own
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    #we need to do a post push to github, clear the stored caches in all edge cache locations coz default TTL is 24hr. 
    #command 
    #   aws cloudfront create-invalidation \
    #   --distribution-id <my-distribution-id from output, just here and execute> \
    #   --paths "/*"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Provides free https://d111111abcdef8.cloudfront.net SSL
  }
}

output "cloudfront_https_url" {
  description = "Live HTTPS URL served via Amazon CloudFront CDN"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}
output "cloudfront_distribution_id" {
  description = "only to get the distribution id"
  value       = aws_cloudfront_distribution.s3_distribution.id
}