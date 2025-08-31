variable "name" { type = string }
variable "eks_version" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_types" { type = list(string) }
variable "tags" { type = map(string) }

variable "cluster_endpoint_public_access"  { type = bool }
variable "cluster_endpoint_private_access" { type = bool }
variable "cluster_endpoint_public_access_cidrs" { type = list(string) }

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
