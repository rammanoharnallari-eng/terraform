variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "tags" { type = map(string) }
