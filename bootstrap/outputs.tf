output "state_bucket" {
  value       = aws_s3_bucket.state.bucket
  description = "Name of the S3 bucket for Terraform state"
}

output "dynamodb_table" {
  value       = aws_dynamodb_table.lock.name
  description = "Name of the DynamoDB table for Terraform state locking"
}
