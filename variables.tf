variable "project_name" {
  default = "terraform-vpc-ec2-lb"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}
variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}
variable "instance_type" {
  default = "t2.micro"
}

variable "ami" {
  default = "ami-0861f4e788f5069dd"
}
