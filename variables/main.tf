#creating a vpc

resource "aws_vpc" "babyvpc" {
    cidr_block = "10.0.0.0/16"

    tags = local.tags
  
}

#creating the security group with for each meta argument

resource "aws_security_group" "sg_baby" {
    name = "${local.full_project_name}-sg"
    description = "Security group for ${var.project_name} in ${var.environment} environment"
    vpc_id = aws_vpc.babyvpc.id

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

#ec2 instance with lifecycle meta argument. 
resource "aws_instance" "practice_server" {
    ami = "ami-0c02fb55956c7d316"
    instance_type = var.instance_type
    region = var.aws_region
    vpc_security_group_ids = [aws_security_group.sg_baby.id]

    tags = local.tags

    lifecycle {
      ignore_changes = [ tags ] 
    }
}

#iam users with count (meta argument)
resource "aws_iam_user" "team" {
    count = length(var.team_members)
    name = "member-${var.team_members[count.index]}"

    tags = local.tags
  
}
    
#s3 bucket with lifecycle
resource "aws_s3_bucket" "practice_bucket" {
    bucket = "${local.full_project_name}-bucket"
    tags = local.tags

    lifecycle {
        prevent_destroy = false
    }
}

# #conditional rds using count
resource "aws_db_instance" "practice_db" {
    count = var.create_rds ? 1 : 0
    identifier = "${local.full_project_name}-db"   #name of the database
    allocated_storage = 20
    engine = "mysql"
    instance_class = "db.t3.micro"
    username = "admin"      
    password = "password1234"
    skip_final_snapshot = true

    vpc_security_group_ids = [aws_security_group.sg_baby.id]
    # db_subnet_group_name   = "default"   # Change when you have real subnets

  tags = local.tags

  depends_on = [aws_vpc.babyvpc]
}