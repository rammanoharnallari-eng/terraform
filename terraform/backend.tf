terraform {
  backend "s3" {
    bucket         = "terraform-state220785"
    key            = "devops-practical-eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
    profile        = "default"
  }
}