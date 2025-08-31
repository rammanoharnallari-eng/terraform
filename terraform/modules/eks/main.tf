module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = "${var.name}-eks"
  cluster_version = var.eks_version
  enable_irsa     = true

  cluster_endpoint_public_access        = var.cluster_endpoint_public_access
  cluster_endpoint_private_access       = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs  = var.cluster_endpoint_public_access_cidrs

  # Enable cluster access entry for better authentication
  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  eks_managed_node_groups = {
    general = {
      name           = "general-v2"  # Force new node group creation
      desired_size   = 3
      min_size       = 3
      max_size       = 10
      instance_types = var.instance_types
      capacity_type  = "ON_DEMAND"
      labels         = { pool = "general" }
      
      # Use default EKS-optimized AMI
      # ami_id = var.custom_ami_id
      
      # Enhanced security and monitoring
      enable_bootstrap_user_data = true
      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=pool=general'"
      
      # Simple block device mapping to avoid launch template issues
      disk_size = 50
      
      # Taints for workload isolation
      taints = var.node_taints
      
      # Update configuration with more aggressive settings
      update_config = {
        max_unavailable_percentage = 50
      }
      
      # Force replacement if needed
      force_update_version = true
      
      # Add lifecycle to force replacement on changes
      lifecycle = {
        create_before_destroy = true
      }
    }
  }

  create_cloudwatch_log_group = false
  cluster_encryption_config = []
  tags = var.tags
}

output "cluster_name" { value = module.eks.cluster_name }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
