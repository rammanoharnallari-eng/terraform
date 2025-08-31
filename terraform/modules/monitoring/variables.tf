variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for Grafana"
}

variable "enable_ingress" {
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
