# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = local.common_tags
}

# Security Group with Dynamic Block
resource "aws_security_group" "main" {
  name        = "${local.full_project_name}-sg"  # string interpolation
  vpc_id      = aws_vpc.main.id
  description = "Security Group created using Terraform functions"

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

  tags = local.common_tags
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  
}



# EC2 Instance
resource "aws_instance" "practice" {
  ami           = "ami-09ed39e30153c3bf9"   # ap-south-1 Amazon Linux
  instance_type = local.instance_type  #coming from lookup function

  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]

  tags = merge(local.common_tags, {
    Name = format("%s-server-%s", var.project-name, local.short_uuid)
  })
}

resource "aws_db_instance" "practice" {
  count = local.should_create_rds ? 1 : 0

  identifier = format("%s-db-%s", var.project-name, local.short_uuid)
  engine     = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  skip_final_snapshot  = true
  final_snapshot_identifier = null
  username = "admin"
  password = "password123"

  tags = merge(local.common_tags, {
    Name = format("%s-db-%s", var.project-name, local.short_uuid)
  })
}

# S3 Bucket using functions
resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket_prefix}-${local.short_uuid}"

  tags = local.common_tags
}

# IAM Users with count + functions
resource "aws_iam_user" "team" {
  count = length(var.team_members)

  name = format("%s-%s", 
    lower(var.team_members[count.index]), 
    var.environment
  )

  tags = local.common_tags
}