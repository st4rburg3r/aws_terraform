terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"  # Change to your preferred region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu official)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
  
}

data "aws_subnet" "default" {

  filter {
    name = "availability-zone"
    values = ["ap-south-1a"]
  }
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name = "default-for-az"
    values = ["true"]
  }

  
}

#security group to allow SSH access
resource "aws_security_group" "ssh_access" {
  name        = "ssh_access"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "remote-exec-sg"

  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id  # Use the data source to get the latest AMI ID
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  subnet_id              = data.aws_subnet.default.id 

  tags = {
    Name = "local-exec-practice"
  }


  # Local-exec example - runs AFTER the instance is created
  provisioner "local-exec" {
    command = <<EOT
      echo "=== EC2 Instance Created Successfully ==="
      echo "Instance ID: ${self.id}"
      echo "Public IP: ${self.public_ip}"
      echo "Creation timestamp: $(date)" >> ec2-deployment.log
      
      echo "Waiting for instance to be visible in EC2 API..."
      
      # Add retry logic - critical for reliability
      for i in {1..10}; do
        STATE=$(aws ec2 describe-instances \
          --instance-ids ${self.id} \
          --query "Reservations[0].Instances[0].State.Name" \
          --output text 2>/dev/null || echo "pending")
        
        if [ "$STATE" = "running" ]; then
          echo "Instance is now running!"
          break
        fi
        
        echo "Attempt $i: Instance not ready yet... waiting 5s"
        sleep 5
      done
    EOT
  }

      provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} destroyed at $(date)' >> ec2-deployment.log"
  }

/*
  ------------------------------------------------------------------
  Provisioner 2: remote-exec
  - Runs commands on the remote instance over SSH.
  - Requires SSH access (security group + key pair + reachable IP).
  - To demo: uncomment this block, ensure `var.private_key_path` is correct, then run `terraform apply`.
  ------------------------------------------------------------------
  */

  provisioner "remote-exec" {

    connection {
    type        = "ssh"
    user        = var.ssh_user  # Default user for Amazon Linux 2
    private_key = file(var.private_key_path)  # Path to your private key
    host        = self.public_ip
  }

    inline = [
      "sudo apt-get update",
      "echo 'Hello from remote-exec' | sudo tee /tmp/remote_exec.txt",
    ]
    
  }

  provisioner "file" {
    source      = "${path.module}/welcome.sh"  # Ensure this file exists in your project directory
    destination = "/tmp/welcome.sh"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = file(var.private_key_path)
      host        = self.public_ip
    }
    
  }

}

output "instance_public_ip" {
  value = aws_instance.example.public_ip
}

