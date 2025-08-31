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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  create_vpc                 = true
  name = "${var.name}-vpc"
  cidr = var.vpc_cidr
  azs  = var.azs

  # Create subnets for each availability zone
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i + 8)]

  map_public_ip_on_launch = true

  
  # NAT configuration - keep egress but use ONLY ONE EIP
  enable_nat_gateway     = true
  single_nat_gateway     = true        # << only one NAT for all private subnets
  one_nat_gateway_per_az = false       # << make sure module doesn't create 1-per-AZ

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

output "vpc_id"             { value = module.vpc.vpc_id }
output "private_subnet_ids" { value = module.vpc.private_subnets }
output "public_subnet_ids"  { value = module.vpc.public_subnets }

locals {
  vpc_effective_id          = var.existing_vpc_id != "" ? var.existing_vpc_id : module.vpc.vpc_id
  private_subnets_effective = length(var.existing_private_subnet_ids) > 0 ? var.existing_private_subnet_ids : module.vpc.private_subnets
  public_subnets_effective  = length(var.existing_public_subnet_ids)  > 0 ? var.existing_public_subnet_ids  : module.vpc.public_subnets
}

