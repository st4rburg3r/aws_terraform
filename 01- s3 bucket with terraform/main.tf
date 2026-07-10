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

# Create a S3 bucket
resource "aws_s3_bucket" "bucket01" {
  bucket = "terraform-practice-bucket-twupsssss"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
