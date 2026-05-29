#primary vpc in ap-south-1 region
resource "aws_vpc" "primary_vpc" {

  cidr_block       = "10.0.0.0/16"
  provider = aws.primary
  enable_dns_hostnames = true  #need to enable this for the primary vpc to allow instances to resolve hostnames of instances in the peered vpc
  enable_dns_support = true

  tags = {
    Name = "Primary-VPC-${var.primary}"
  }
}

resource "aws_vpc" "secondary_vpc" {
  cidr_block       =  var.secondary_vpc_cidr
  provider = aws.secondary
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Secondary-VPC-${var.secondary}"
  }
}

#creating subnets in both vpcs 

resource "aws_subnet" "primary_subnet" {
    provider = aws.primary
    vpc_id            = aws_vpc.primary_vpc.id
    cidr_block        = var.primary_subnet_cidr
    availability_zone = data.aws_availability_zones.primary.names[0]  #here we are not hardcoding the availability zone, instead we are using the data source to get the available zone in the region, this makes our code more flexible and reusable
    map_public_ip_on_launch = true

    tags = {
        Name = "Primary-Subnet-${var.primary}"
    }
}
resource "aws_subnet" "secondary_subnet" {
    provider = aws.secondary
    vpc_id            = aws_vpc.secondary_vpc.id
    cidr_block        = var.secondary_subnet_cidr
    availability_zone = data.aws_availability_zones.secondary.names[0]  #here we are not hardcoding the availability zone, instead we are using the data source to get the available zone in the region, this makes our code more flexible and reusable
    map_public_ip_on_launch = true

    tags = {
        Name = "Secondary-Subnet-${var.secondary}"
    }
}

#creating an internet gateway and attaching it to the primary vpc, this is required to allow instances in the primary vpc to access the internet and also to allow instances in the secondary vpc to access the internet through the peering connection

resource "aws_internet_gateway" "igw_primary" {
    provider = aws.primary
    vpc_id = aws_vpc.primary_vpc.id

    tags = {
        Name = "Primary-IGW-${var.primary}"
    }
  
}

resource "aws_internet_gateway" "igw_secondary" {
    provider = aws.secondary
    vpc_id = aws_vpc.secondary_vpc.id

    tags = {
        Name = "Secondary-IGW-${var.secondary}"
    }
  
}

#creating route tables for both vpcs, we will use these route tables to add routes for the peering connection

# ==================== PRIMARY ROUTE TABLE ====================
resource "aws_route_table" "rt_primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  # Route to Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_primary.id
  }

  tags = {
    Name = "Primary-RT-${var.primary}"
  }
}

# ==================== SECONDARY ROUTE TABLE ====================
resource "aws_route_table" "rt_secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  # Route to Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_secondary.id
  }

  tags = {
    Name = "Secondary-RT-${var.secondary}"
  }
}


#creating aws route table associations to associate the route tables with the respective subnets, this is required to ensure that the routes we add to the route tables are effective for the instances in the subnets

resource "aws_route_table_association" "rta_primary" {
    provider = aws.primary
    subnet_id      = aws_subnet.primary_subnet.id
    route_table_id = aws_route_table.rt_primary.id

}

resource "aws_route_table_association" "rta_secondary" {
    provider = aws.secondary
    subnet_id      = aws_subnet.secondary_subnet.id
    route_table_id = aws_route_table.rt_secondary.id

}

resource "aws_vpc_peering_connection" "primary_to_secondary" {
    provider = aws.primary
    vpc_id = aws_vpc.primary_vpc.id
    peer_vpc_id = aws_vpc.secondary_vpc.id
    peer_region = var.secondary
    auto_accept = false  #we will manually accept the peering connection from the secondary region, this is just for demonstration purposes, in a real-world scenario, you can set this to true to automatically accept the peering connection)

    tags = {
        Name = "Primary-to-Secondary-Peering"
    }

  
}

resource "aws_vpc_peering_connection_accepter" "secondary_to_primary" {
    provider = aws.secondary
    vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
    auto_accept = true

    tags = {
        Name = "Secondary-to-Primary-Peering"
    }
  
}

# ==================== PEERING ROUTES (Separate) ====================
# Add route to Secondary VPC in Primary route table
resource "aws_route" "primary_to_secondary" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.rt_primary.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_to_primary]
}

# Add route to Primary VPC in Secondary route table
resource "aws_route" "secondary_to_primary" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.rt_secondary.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_to_primary]
}


#security group for primary vpc ec2 instance, we will allow all traffic from the secondary vpc to the primary vpc, this is just for testing the connectivity between the peered vpcs, in a real-world scenario, you should restrict the traffic based on your requirements

resource "aws_security_group" "sg_primary" {
    provider = aws.primary
    name = "Primary-SG"
    description = "Security group for primary vpc"
    vpc_id = aws_vpc.primary_vpc.id

    ingress {
        description = "Allow SSH from anywhere"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "ICMP from secondary vpc"
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = [var.secondary_vpc_cidr]
    }

    ingress {
    description = "All traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Primary-SG"
    }
}

resource "aws_security_group" "sg_secondary" {
    provider = aws.secondary
    name = "Secondary-SG"
    description = "Security group for secondary vpc"
    vpc_id = aws_vpc.secondary_vpc.id

    ingress {
        description = "Allow SSH from anywhere"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "ICMP from primary vpc"
        from_port   = -1
        to_port     = -1
        protocol    = "icmp"
        cidr_blocks = [var.primary_vpc_cidr]
    }

    ingress {
    description = "All traffic from Primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Secondary-SG"
    }
}

#ec2 instances in both vpcs to test the connectivity between the peered vpcs

resource "aws_instance" "primary_instance" {
    provider = aws.primary
    ami = data.aws_ami.primary_ami.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.primary_subnet.id
    vpc_security_group_ids =  [aws_security_group.sg_primary.id]
    # security_groups = [aws_security_group.sg_primary.name]
    key_name = var.primary_key_pair_name

     user_data = local.primary_user_data

    tags = {
        Name = "Primary-Instance"
        Region = var.primary
    }
   depends_on = [ aws_vpc_peering_connection_accepter.secondary_to_primary ]
}

resource "aws_instance" "secondary_instance" {
    provider = aws.secondary
    ami = data.aws_ami.secondary_ami.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.secondary_subnet.id
    vpc_security_group_ids =  [aws_security_group.sg_secondary.id]
    # security_groups = [aws_security_group.sg_secondary.name]
    key_name = var.secondary_key_pair_name

    user_data = local.secondary_user_data

    tags = {
        Name = "Secondary-Instance"
        Region = var.secondary
    }
  depends_on = [ aws_vpc_peering_connection_accepter.secondary_to_primary ]
}








