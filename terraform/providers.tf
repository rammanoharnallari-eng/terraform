provider "aws" { region = var.region }

data "aws_availability_zones" "available" {}

# Wait for EKS cluster to be active
data "aws_eks_cluster" "this" {
  depends_on = [module.eks]
  name = module.eks.cluster_name
  
  # This will wait for the cluster to be in ACTIVE state
  lifecycle {
    postcondition {
      condition = self.status == "ACTIVE"
      error_message = "EKS cluster is not in ACTIVE state"
    }
  }
}

data "aws_eks_cluster_auth" "this" {
  depends_on = [data.aws_eks_cluster.this]
  name = module.eks.cluster_name
}

# Add a longer delay to ensure the cluster is fully ready
resource "time_sleep" "wait_for_cluster_ready" {
  depends_on = [data.aws_eks_cluster_auth.this]
  create_duration = "300s"
}

# Add current AWS identity to EKS cluster aws-auth ConfigMap
resource "null_resource" "add_aws_auth" {
  depends_on = [time_sleep.wait_for_cluster_ready]
  
  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}
      echo "Adding current AWS identity to EKS cluster..."
      
      # Get current AWS identity
      AWS_IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text)
      echo "Current AWS identity: $AWS_IDENTITY"
      
      # Add to aws-auth ConfigMap
      kubectl patch configmap aws-auth -n kube-system --patch '{
        "data": {
          "mapUsers": "[{\"userarn\":\"'$AWS_IDENTITY'\",\"username\":\"admin\",\"groups\":[\"system:masters\"]}]"
        }
      }' || echo "Failed to patch aws-auth, continuing..."
      
      echo "AWS auth configuration completed"
    EOT
  }
  
  triggers = {
    cluster_name = module.eks.cluster_name
    region       = var.region
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}


data "aws_vpc" "default" {
  default = true
}


data "aws_subnets" "public" {
  filter {
  name   = "vpc-id"
  values = [data.aws_vpc.default.id]
}
  filter {
  name   = "map-public-ip-on-launch"
  values = ["true"]
}
}


data "aws_subnets" "private" {
  filter {
  name   = "vpc-id"
  values = [data.aws_vpc.default.id]
}
  filter {
  name   = "map-public-ip-on-launch"
  values = ["false"]
}
}


data "aws_subnets" "all_in_default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


data "aws_subnet" "details" {
  for_each = toset(data.aws_subnets.all_in_default.ids)
  id       = each.value
}


locals {
  default_public_subnets = [for s in data.aws_subnet.details : s.id if s.map_public_ip_on_launch]
}
