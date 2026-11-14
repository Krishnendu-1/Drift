resource "aws_s3_bucket" "website_bucket" {
  bucket        = var.website_bucket_name
  force_destroy = true
}

#This resource just make the bucket a http endpoint
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket     = aws_s3_bucket.website_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.website_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontAcessReadOnly" #statement Id
        Effect = "Allow"                   #allow or deny, the outcome of the policy
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }                                                  #who should have the access to allow or deny(effect)
        Action   = "s3:GetObject"                          #the operations allowed to do
        Resource = "${aws_s3_bucket.website_bucket.arn}/*" #what resources
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket        = "${var.website_bucket_name}-pipeline-artifacts"
  force_destroy = true
}

#there might be a question, why we need two buckets?? One is public and another one is private
#--> coz, codepipeline under the hood can't store the files in memory to pass to the next stage, it need a intermediary artifact(.zip) storage from where the next stage will pull the .zip file, extracts it. The final deploy stage extracts the artifact and pass to the public bucket