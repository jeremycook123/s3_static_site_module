resource "random_pet" "suffix" {
  separator = ""
}

locals {
  random_suffix = var.create_random_suffix ? "${var.bucket_name}-${random_pet.suffix.id}" : var.bucket_name
  name_with_env = "${local.random_suffix}-${var.environment}"
}

resource "aws_s3_bucket" "website" {
  bucket        = local.name_with_env
  tags          = var.tags
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "publiceaccess" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.publiceaccess,
  ]

  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
}

# resource "aws_s3_object" "error" {
#   bucket       = aws_s3_bucket.website.id
#   key          = "error.html"
#   source       = "error.html"
#   content_type = "text/html"
# }

resource "aws_s3_object" "js_folder" {
  for_each = fileset("${path.module}/js", "*.js")
  bucket   = aws_s3_bucket.website.id
  key      = each.key
  source   = "js/${each.key}"
}

# resource "aws_s3_object" "error_folder" {
#   for_each = fileset("error_files", "**/*")
#   bucket   = aws_s3_bucket.website.id
#   key      = each.key
#   source   = "error_files/${each.key}"
# }

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  # error_document {
  #   key = "error.html"
  # }

  routing_rule {
    condition {
      key_prefix_equals = "js/"
    }
    redirect {
      replace_key_prefix_with = "js/"
    }
  }
}

resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.website.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
   "Principal": "*",
      "Action": [ "s3:GetObject" ],
      "Resource": [
        "${aws_s3_bucket.website.arn}",
        "${aws_s3_bucket.website.arn}/*"
      ]
    }
  ]
}
EOF
}
