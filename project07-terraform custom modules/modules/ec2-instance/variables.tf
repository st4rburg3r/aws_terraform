variable "instance-name" {
  description = "The name of the EC2 instance"
  type        = string
  default     = "proj-07 instance"
  
}

variable "instance-type" {
  description = "The type of the EC2 instance"
  type        = string
  default     = "t3.micro"
  
}

variable "key-name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
  default     = "proj-07-key"
  
}

variable "private-key-path" {
  description = "The path to the private key file for SSH access"
  type        = string
  default     = "/proj-07-key.pem"
}

variable "allowed-ip" {
  description = "The IP address allowed to access the EC2 instance"
  type        = string
  default     = "103.184.104.101/32"
  
}

variable "default-user" {
  description = "The default user for the EC2 instance"
  type        = string
  default     = "ec2-user"
  
}

variable "subnet-id" {
    description = "The ID of the subnet to launch the EC2 instance in"
    type        = string
}
