# data source to get the existing vpc

data "aws_vpc" "shared" {
    filter {
      name = "tag:Name"
      values =  ["shared-network-vpc"]
    }
  
}

#data soiurce to get the existing subnet

data "aws_subnet" "shared" {
    filter {
      name = "tag:Name"
      values =  ["shared-primary-subnet"]
    }

}

#data source to get the latest amazon linux 2 ami
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


resource "aws_instance" "main" {
    ami = data.aws_ami.amazon_linux.id
    instance_type = "t3.micro"
    subnet_id = data.aws_subnet.shared.id
    tags = {
        Name = "practice-aws-Network-EC2"
    }
}