variable "namespace" { type = string }
variable "chart_path" { type = string }
variable "image_repository" { type = string }
variable "image_tag" { type = string }

variable "mongo_app_user" { type = string }
variable "mongo_app_password" {
  type      = string
  sensitive = true
}
variable "mongo_app_database" { type = string }
