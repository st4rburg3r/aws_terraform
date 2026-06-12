output "instance-id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.this.id
  
}

output "public-ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
  
}

output "sg_id" {
  value = aws_security_group.this.id
}