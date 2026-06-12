terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

#call the module

module "ec2" {
    source = "./modules/ec2-instance"

    # Below are INPUT VARIABLES you pass into the module

    instance-name = "remote-exec-and-modules"
    instance-type = var.instance_type
    subnet-id     = data.aws_subnet.default.id
    # security-groups = aws_security_group.allow_all.id
    key-name      = var.key_name
  
}