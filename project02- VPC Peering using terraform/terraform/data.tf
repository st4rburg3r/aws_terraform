data "aws_availability_zones" "primary" {
    provider = aws.primary
    state = "available"

}

data "aws_availability_zones" "secondary" {
    provider = aws.secondary
    state = "available"
  
}

#data source for primary region ami, we will use this ami to launch ec2 instances in the primary vpc, this is just for testing the connectivity between the peered vpcs, we can use any ami for this purpose
#the ami id can vary in different regions, so we are using the data source to get the most recent ami id for the amazon linux 2 ami in the respective regions.
data "aws_ami" "primary_ami" {
    provider = aws.primary
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

data "aws_ami" "secondary_ami" {
    provider = aws.secondary
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

