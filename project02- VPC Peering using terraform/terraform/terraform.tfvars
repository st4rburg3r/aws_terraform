primary = "ap-south-1"
secondary = "ap-southeast-1"


primary_vpc_cidr   = "10.0.0.0/16"
secondary_vpc_cidr = "10.1.0.0/16"

primary_subnet_cidr   = "10.0.1.0/24"
secondary_subnet_cidr = "10.1.1.0/24"

instance_type = "t3.micro"

# IMPORTANT: Create an EC2 key pair in both regions before running this demo
# Use different key names for clarity
primary_key_pair_name   = "primary-key-pair"
secondary_key_pair_name = "secondary-key-pair"
