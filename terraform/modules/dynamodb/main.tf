resource "aws_dynamodb_table" "links" {
  name         = "${var.project_name}-links"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "slug"

  attribute {
    name = "slug"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-links"
  })
}

resource "aws_dynamodb_table" "rate_limits" {
  name         = "${var.project_name}-rate-limits"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "client_ip"

  attribute {
    name = "client_ip"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-rate-limits"
  })
}
