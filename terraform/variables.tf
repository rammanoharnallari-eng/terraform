variable "name"            { type = string  default = "swimlane" }
variable "region"          { type = string  default = "ap-south-1" }
variable "vpc_cidr"        { type = string  default = "10.20.0.0/16" }
variable "eks_version"     { type = string  default = "1.30" }
variable "instance_types"  { type = list(string) default = ["t3.large"] }

# App image
variable "image_repository" { type = string }
variable "image_tag"        { type = string  default = "v1" }

# Mongo config
variable "mongo_app_user"      { type = string  default = "appuser" }
variable "mongo_app_password"  { type = string  sensitive = true }
variable "mongo_app_database"  { type = string  default = "appdb" }
