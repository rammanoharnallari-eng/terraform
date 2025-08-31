locals {
  suffix         = random_id.suffix.hex
  account_id     = data.aws_caller_identity.current.account_id
  default_bucket = "tfstate-${local.account_id}-${var.region}-${local.suffix}"
  default_table  = "tf-lock-${local.account_id}-${var.region}"
  bucket_name    = length(var.bucket_name) > 0 ? var.bucket_name : local.default_bucket
  table_name     = length(var.table_name)  > 0 ? var.table_name  : local.default_table
}

resource "random_id" "suffix" { byte_length = 3 }

resource "aws_s3_bucket" "tf_state" { bucket = local.bucket_name }

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.tf_state.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.tf_state.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

data "aws_iam_policy_document" "deny_insecure_transport" {
  statement {
    sid = "DenyInsecureTransport"
    principals { type = "*", identifiers = ["*"] }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.tf_state.arn, "${aws_s3_bucket.tf_state.arn}/*"]
    condition { test = "Bool", variable = "aws:SecureTransport", values = ["false"] }
    effect = "Deny"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.tf_state.id
  policy = data.aws_iam_policy_document.deny_insecure_transport.json
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute { name = "LockID"; type = "S" }
}

output "state_bucket" { value = aws_s3_bucket.tf_state.bucket }
output "lock_table"   { value = aws_dynamodb_table.tf_lock.name }
output "region"       { value = var.region }
