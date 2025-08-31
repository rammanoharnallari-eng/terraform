terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws         = { source = "hashicorp/aws", version = "~> 5.50" }
    kubernetes  = { source = "hashicorp/kubernetes", version = "~> 2.29" }
    helm        = { source = "hashicorp/helm", version = "~> 2.12" }
    random      = { source = "hashicorp/random", version = "~> 3.6" }
  }
}
