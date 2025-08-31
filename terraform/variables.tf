variable "name" {
  type    = string
  default = "swimlane"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "image_repository" {
  type = string
}

variable "image_tag" {
  type    = string
  default = "v1"
}

variable "mongo_app_user" {
  type    = string
  default = "appuser"
}

variable "mongo_app_password" {
  type      = string
  sensitive = true
}

variable "mongo_app_database" {
  type    = string
  default = "appdb"
}

variable "cluster_endpoint_public_access" {
  type = bool
  default = true
}
variable "cluster_endpoint_private_access" {
  type = bool
  default = true
}
variable "cluster_endpoint_public_access_cidrs" {
  type = list(string)
  default = ["0.0.0.0/0"]
}

variable "custom_ami_id" {
  type        = string
  default     = null
  description = "Custom AMI ID for worker nodes (built with Packer)"
}

variable "node_taints" {
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default     = []
  description = "Taints to apply to worker nodes"
}

variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for Grafana"
  default     = "admin123!"
}

variable "enable_monitoring_ingress" {
  type        = bool
  default     = false
  description = "Enable ALB ingress for Grafana"
}

variable "grafana_domain" {
  type        = string
  default     = "grafana.example.com"
  description = "Domain name for Grafana"
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "ACM certificate ARN for HTTPS"
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of existing public subnet IDs to use instead of creating new ones"
}

variable "excluded_availability_zones" {
  type        = list(string)
  default     = ["us-east-1e"]  # EKS doesn't support us-east-1e
  description = "List of availability zones to exclude from EKS cluster creation"
}
