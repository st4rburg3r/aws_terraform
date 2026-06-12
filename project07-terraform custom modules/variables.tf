variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
}

variable "private_key_path" {
  description = "Local path to the private key file"
  type        = string
  sensitive   = true
}

variable "my_public_ip" {
  description = "Your public IP address for SSH access (use /32)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}