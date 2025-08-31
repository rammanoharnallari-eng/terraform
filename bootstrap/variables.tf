variable "name" {
  description = "Project name used for tagging and naming resources"
  type        = string
  default     = "swimlane"
}

variable "region" {
  description = "AWS region to create the backend resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Prefix for the S3 state bucket (suffix and account id will be appended)"
  type        = string
  default     = "tf-state"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "tf-locks"
}

variable "force_destroy" {
  description = "Allow destroy even if bucket is not empty"
  type        = bool
  default     = false
}
