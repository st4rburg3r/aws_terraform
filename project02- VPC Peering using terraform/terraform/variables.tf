variable "primary" {
    type = string
    default = "ap-south-1"
}

variable "secondary" {
    type = string
    default = "ap-southeast-1"
}

variable "primary_vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
    type = string
    default = "10.1.0.0/16"
}

variable "primary_subnet_cidr" {
    type = string
    default = "10.0.1.0/24"
  
}

variable "secondary_subnet_cidr" {
    type = string
    default = "10.1.1.0/24"
  
}

variable "instance_type" {
    type = string
    default = "t2.micro"
}

variable "primary_key_pair_name" {
    type = string
    default = ""
  
}

variable "secondary_key_pair_name" {
    type = string
    default = ""
  
}