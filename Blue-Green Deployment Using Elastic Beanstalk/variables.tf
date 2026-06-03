
variable "app_name" {
  description = "The name of the Elastic Beanstalk application"
  type        = string
  default     = "blue-green-demo-app"
  
}

variable "solution_stack_name" {
  description = "Elastic Beanstalk solution stack name (platform)"
  type        = string
  # Node.js 22 running on 64bit Amazon Linux 2023
  default = "64bit Amazon Linux 2023 v6.11.1 running Node.js 22"
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
  
}

variable "instance_type" {
  description = "The EC2 instance type for the Elastic Beanstalk environment"
  type        = string
  default     = "t2.micro"
  
}

variable "tags" {
  description = "A map of tags to apply to resources"
  type        = map(string)
  default     = {
    Environment = "Demo"
    Project     = "Blue-Green Deployment"
  }
  
}