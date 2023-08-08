variable "region" {
  default = "ap-south-1"
}

variable "vpc_name" {
  default = "EKS-VPC"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "igw_name" {
  default = "EKS-IGW"
}

variable "azs" {
  type    = list(any)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "subnet_cidr" {
  type    = list(any)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "cluster_name" {
  default = "cluster-1"
}

variable "ami_id" {
  default = "ami-021f7978361c18b01"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_pair" {
  default = "linux"
}