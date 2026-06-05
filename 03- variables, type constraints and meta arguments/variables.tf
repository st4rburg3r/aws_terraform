variable "project_name" {
    description = "project name for tagging"
    type        = string
    default     = "dubai-cloud-practice"
}

variable "environment" {
    description = "deployment env"
    type = string
    default = "dev"

    validation {
        condition     = contains(["dev", "staging", "prod"], var.environment)
        error_message = "Environment must be one of 'dev', 'staging', or 'prod'."
    }
}

variable "aws_region" {
    description = "AWS Region"
    type = string
    default = "ap-south-1"
}

variable "instance_type" {
    description = "EC2 instance type"
    type        = string
    default     = "t3.micro"
}

variable "allowed_ports" {
    description = "List of allowed ports for security group"
    type        = list(number)
    default     = [22, 80, 443]

    validation {
      condition = length(var.allowed_ports)>0
      error_message = "Atleart one port must be allowed"

    }
}

variable "common_tags" {
    description = "Common tags for all resources"
    type        = map(string)
    default     = {
        Project     = "dubai-cloud-practice"
        Owner       = "Trupti"
        ManagedBy    = "Terraform"
        Environment = "dev"
    }
}

variable "create_rds" {
    description = "whether to create RDS instance"
    type = bool
    default = false
  
}

variable "team_members" {
    description = "List of team members for IAM users"
    type = list(string)
    default = ["Trupti", "John", "Alice"]
  
}
variable "key_name" {
    description = "SSH Key pair name"
    type = string
    default = null
  
}