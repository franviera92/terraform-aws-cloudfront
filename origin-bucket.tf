resource "aws_s3_bucket" "origin" {
  bucket = local.bucket_name
  force_destroy = var.force_destroy
  lifecycle {
    prevent_destroy = false
  }
  logging {
    target_bucket = data.aws_s3_bucket.log_bucket.id
    target_prefix = "s3/${local.bucket_name}/"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = local.tags
  versioning {
    enabled = var.versioning
  }
}

data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    actions = [
      "s3:*",
    ]
    condition {
      test = "Bool"
      values = [
        "false",
      ]
      variable = "aws:SecureTransport"
    }
    effect = "Deny"
    principals {
      identifiers = [
        "*",
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.origin.arn,
      "${aws_s3_bucket.origin.arn}/*",
    ]
    sid = "DenyUnsecuredTransport"
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    principals {
      identifiers = [
        aws_cloudfront_origin_access_identity.origin.iam_arn,
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.origin.arn,
      "${aws_s3_bucket.origin.arn}/*",
    ]
    sid = "AllowCloudFront"
  }
}

resource "aws_s3_bucket_policy" "origin" {
  bucket = aws_s3_bucket.origin.id
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

