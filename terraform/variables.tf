variable "cluster-name" {
  default = "develop_cluster"
  type    = string
}

variable "azs" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  type    = list(string)
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "private_subnets"{
  default = ["10.0.1.0/24", "10.0.2.0/24"]
  type    = list(string)
}

variable "public_subnets" {
  default = ["10.0.101.0/24"]
  type    = list(string)
}