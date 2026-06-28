resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-frontend-${data.aws_caller_identity.current.account_id}"
  tags   = merge(var.tags, { Name = "${var.project_name}-frontend" })
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  web_files = fileset(var.web_root, "**")
}

resource "aws_s3_object" "web" {
  for_each = { for file in local.web_files : file => file }

  bucket       = aws_s3_bucket.this.id
  key          = each.key
  source       = "${var.web_root}/${each.key}"
  etag         = filemd5("${var.web_root}/${each.key}")
  content_type = length(regexall("\\.[^.]+$", each.key)) > 0 ? lookup(local.content_types, regex("\\.[^.]+$", each.key), "application/octet-stream") : "application/octet-stream"
}

locals {
  content_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".ico"  = "image/x-icon"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
  }
}
