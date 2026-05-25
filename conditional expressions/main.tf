resource "aws_vpc" "babyvpc" {
    cidr_block = "10.0.0.0/16"

    tags = local.tags
  
}

#creating the security group with for each meta argument

resource "aws_security_group" "sg_baby" {
    name = "${local.full_project_name}-sg"
    description = "Security group for ${var.project_name} in ${var.environment} environment"
    vpc_id = aws_vpc.babyvpc.id

    #using for each meta argument for dynamic blocks

    # A dynamic block lets you create repeating nested blocks (like ingress rules, tags, or steps) dynamically based on a list or map.
    dynamic "ingress" {
        for_each = var.allowed_ports
        content {
            from_port   = ingress.value
            to_port     = ingress.value
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]

    }
    tags = local.tags

}


#conditional instance

resource "aws_instance" "practice" {
    count = var.environment == "dev" ? 2 : 1
    ami = "ami-09ed39e30153c3bf9"
    instance_type = var.environment == "prod" ? "t3.small" : var.instance_type

    vpc_security_group_ids = [aws_security_group.sg_baby.id] 

    tags = merge(local.tags, {
        Role = var.environment == "prod" ? "production-server" : "development-server"
    })   

}
