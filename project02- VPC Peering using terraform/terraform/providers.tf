terraform {  
    required_version = ">= 1.5.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}


#creating resources in multiple regions, so we need to define multiple providers with different aliases
provider "aws" {
    region = var.primary
    alias = "primary"
}

provider "aws" {
    region = var.secondary
    alias = "secondary"
  
}
