
variable "region" {
  default = "ap-south-1"
}

variable "environment" {
  default = "DEV"
}

variable "vpc_name" {
  default = "Dev-vpc"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(any)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "subnet_name" {
  type    = list(any)
  default = ["Dev_public_subnet", "Dev_private_subnet"]
}

variable "pub_subnet_cidr" {
  type    = list(any)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "prt_subnet_cidr" {
  type    = list(any)
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "igw_name" {
  default = "Dev-IGW"
}

variable "NAT_name" {
  default = "Dev-NGW"
}

variable "RT_name" {
  type    = list(any)
  default = ["Dev-Public-RT", "Dev-Private-RT"]
}

variable "Load_Balancer_name" {
  default = "Dev-LB"
}

variable "LB_security_group" {
  default = "Dev-LB-SG"
}

variable "public_SG" {
  default = "Dev-Pub-SG"
}

variable "private_SG" {
  default = "Dev-Prt-SG"
}

variable "target_group_name" {
  type = list
  default =["Dev-target-group-1","Dev-target-group-2"]
}

variable "listener_path" {
  type = list
  default = ["/app1/*","/app2/*"]
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

variable "Front_user_data" {
  default = "user_data.sh"
}

variable "Back_user_data" {
  default = "user_data.sh"
}

variable "topic_name" {
  default = "my_topic-1"
}

variable "Protocol_Endpoint" {
  type = list
  default = ["email","siddhu7162@gmail.com"]
}