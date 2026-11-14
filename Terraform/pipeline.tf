resource "aws_codestarconnections_connection" "github" {
  name          = "github-static-site-conn"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "static_site_pipeline" {
  name     = "static-website-s3-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Deploy" #here browser can run smoothly raw .html file as there is no tsx, react, nodejs app...if it's there then aws build stage 1.5 codebuild is required to spin a docker container and install npm dependencies to dist/ folder and then pass it to s3 deploy.

    action {
      name            = "S3_Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.website_bucket.bucket
        Extract    = "true"
      }
    }
  }
}

output "website_endpoint_url" {
  description = "Live URL of the Static Website"
  value       = "http://${aws_s3_bucket_website_configuration.website_config.website_endpoint}"
} #just to check the cloudfront is working or not by denying the access to the bucket

