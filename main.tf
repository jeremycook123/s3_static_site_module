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

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.website.bucket
  index_document {
    suffix = var.index_document
  }
  error_document {
    key = var.error_document
  }
}

resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.allow_public_read.json
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
  }
}
