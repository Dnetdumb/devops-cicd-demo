## Global ##
############
variable "region" { 
  default = "ap-southeast-1" 
}

variable "profile" {
  default = "terraform-operator"
}

## EKS ##
#########

variable "cluster_name" {
  default = "prod-cluster"
}

variable "cluster_version" {
  default = "1.31"
}

variable "instance_type" {
  default = ["t3.small"]
}

variable "desired_size" {
  default = 2
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 3
}

## VPC ##
#########

variable "vpc_name" { 
  default = "my-vpc" 
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}
