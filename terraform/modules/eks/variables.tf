variable "name"               { type = string }
variable "eks_version"        { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_types"     { type = list(string) }
variable "tags"               { type = map(string) }
