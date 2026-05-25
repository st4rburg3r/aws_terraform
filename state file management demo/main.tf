# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # Configuration options
    region = "ap-south-1"
}

# backend configuration
#this bucket should be created before running terraform init command
terraform {
  backend "s3" {
    bucket         = "remote-backend-trupti-demo"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile  = "true"
    encrypt        = true
  }
}


# Simple test resource to verify remote backend
resource "aws_s3_bucket" "test_backend" {
  bucket = "test-remote-backend-trupti-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "Test Backend Bucket"
    Environment = "dev"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}