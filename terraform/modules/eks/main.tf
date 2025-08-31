module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = "${var.name}-eks"
  cluster_version = var.eks_version
  enable_irsa     = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    general = {
      desired_size   = 3
      min_size       = 3
      max_size       = 6
      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"
      labels         = { pool = "general" }
    }
  }

  tags = var.tags
}

output "cluster_name"      { value = module.eks.cluster_name }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
