variable "instance_type"{
type= string
default="t3.large"
}
variable "vpc_id"{
type=string
description="VPC ID where security groups will be created"
}
variable "private_subnet_id"{
type=string
description="Subnet ID where the EC2 instance will be launched"
}
variable "environment"{
type=string
}
variable "public_subnet_1_id" {
type=string
}
variable "public_subnet_2_id" {
type=string
}
