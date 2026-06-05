variable "project-name" {
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
variable "allowed_ports" {
    description = "List of allowed ports for security group"
    type        = list(number)
    default     = [22, 80, 443]

    validation {
      condition = length(var.allowed_ports)>0
      error_message = "Atleart one port must be allowed"

    }
  
}

variable "team_members" {
    description = "List of team members for the project"
    type        = list(string)
    default     = ["Alice", "Bob", "Charlie"]
  
}