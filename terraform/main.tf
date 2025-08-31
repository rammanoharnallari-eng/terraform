module "vpc" {
  source   = "./modules/vpc"
  name     = var.name
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags     = local.tags
}

module "eks" {
  source         = "./modules/eks"
  name           = var.name
  eks_version    = var.eks_version
  vpc_id         = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_types = var.instance_types
  tags           = local.tags
}

module "mongodb" {
  source        = "./modules/mongodb"
  namespace     = "data"
  app_namespace = "apps"
  app_user      = var.mongo_app_user
  app_password  = var.mongo_app_password
  app_database  = var.mongo_app_database

  depends_on = [module.eks]
}

module "app" {
  source            = "./modules/app"
  namespace         = "apps"
  chart_path        = "${path.module}/../helm/swimlane-devops-practical"
  image_repository  = var.image_repository
  image_tag         = var.image_tag
  mongo_app_user    = var.mongo_app_user
  mongo_app_password= var.mongo_app_password
  mongo_app_database= var.mongo_app_database

  depends_on = [module.mongodb]
}
