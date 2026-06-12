data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-kernel-*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ssh" {
    name = "${var.instance-name}-sg"
    description = "Security group for SSH access to ${var.instance-name}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.allowed-ip}"]
        description = "SSH access from allowed IP"
    }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
}
}

resource "aws_instance" "this" {
    ami           = data.aws_ami.amazon_linux_2023.id
    instance_type = var.instance-type
    key_name      = var.key-name
    security_groups = [aws_security_group.ssh.id]
    
    subnet_id = data.aws_subnet.default.id
    
    tags = {
        Name = var.instance-name
    }

    # Local-exec
  provisioner "local-exec" {
    command = <<EOT
      echo "=== EC2 Instance Created Successfully ==="
      echo "Instance ID: ${self.id} | IP: ${self.public_ip}" >> ec2-deployment.log
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance ${self.id} destroyed at $(date)' >> ec2-deployment.log"
  }

    provisioner "remote-exec" {

    connection {
    type        = "ssh"
    user        = var.default-user  # Default user for Amazon Linux 2
    private_key = file(var.private-key-path)  # Path to your private key
    host        = self.public_ip
  }

    inline = [
      "echo 'Hello from remote-exec' | sudo tee /tmp/remote_exec.txt",
    ]
    
  }
  
}

