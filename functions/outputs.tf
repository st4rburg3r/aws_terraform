output "vpc_id" {
  description = "The ID of the VPC created"
  value       = aws_vpc.main.id
  
}

output "security_group_id" {
  description = "The ID of the Security Group created"
  value       = aws_security_group.main.id
  
}

output "ec2_details" {
  description = "Details of the EC2 instance created"
  value = {
    instance_id   = aws_instance.practice.id
    public_ip     = aws_instance.practice.public_ip
    instance_type = aws_instance.practice.instance_type
  }
  
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket created"
  value       = aws_s3_bucket.logs.bucket
  
}

#collection and function output

output "iam_user_names" {
  description = "List of IAM user names created for the team"
  value       = aws_iam_user.team[*].name
  
}
output "number_of_iam_users" {
  description = "Total number of IAM users created"
  value       = length(aws_iam_user.team)
  
}

