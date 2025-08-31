module "vpc" {
  source   = "./modules/vpc"
  name     = var.name
  vpc_cidr = var.vpc_cidr
  azs      = local.eks_supported_azs
  tags     = local.tags
}

locals {
  # Use only EKS-supported availability zones (exclude unsupported AZs)
  eks_supported_azs = [
    for az in data.aws_availability_zones.available.names : az
    if !contains(var.excluded_availability_zones, az)
  ]
  
  eks_subnets = length(module.vpc.private_subnet_ids) > 0 ? module.vpc.private_subnet_ids : (
                 length(var.existing_public_subnet_ids) > 0 ? var.existing_public_subnet_ids : (
                 length(local.default_public_subnets) > 0 ? local.default_public_subnets : data.aws_subnets.all_in_default.ids))
}

module "eks" {
  source             = "./modules/eks"
  name               = var.name
  eks_version        = var.eks_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = local.eks_subnets
  instance_types     = var.instance_types
  tags               = local.tags
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  custom_ami_id      = var.custom_ami_id
  node_taints        = var.node_taints
}

module "mongodb" {
  source        = "./modules/mongodb"
  namespace     = "data"
  app_namespace = "apps"
  app_user      = var.mongo_app_user
  app_password  = var.mongo_app_password
  app_database  = var.mongo_app_database
  depends_on    = [null_resource.add_aws_auth]
}

module "app" {
  source              = "./modules/app"
  namespace           = "apps"
  chart_path          = "${path.module}/../helm/swimlane-devops-practical"
  image_repository    = var.image_repository
  image_tag           = var.image_tag
  mongo_app_user      = var.mongo_app_user
  mongo_app_password  = var.mongo_app_password
  mongo_app_database  = var.mongo_app_database
  depends_on          = [module.mongodb]
}

module "monitoring" {
  source                  = "./modules/monitoring"
  grafana_admin_password  = var.grafana_admin_password
  enable_ingress         = var.enable_monitoring_ingress
  grafana_domain         = var.grafana_domain
  certificate_arn        = var.certificate_arn
  depends_on             = [null_resource.add_aws_auth]
}