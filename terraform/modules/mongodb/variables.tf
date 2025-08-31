variable "namespace"     { type = string }
variable "app_namespace" { type = string }
variable "app_user"      { type = string }
variable "app_password" {
  type = string
  sensitive = true
}
variable "app_database"  { type = string }
