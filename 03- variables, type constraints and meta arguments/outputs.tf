output "instance_id" {
    description = "ID of the EC2 instance"
    value = aws_instance.practice_server.id
}

output "security_group_id" {
    description = "ID of the security group"
    value = aws_security_group.sg_baby.id  
}

output "s3_bucket_name" {
    description = "Name of the S3 bucket"
    value = aws_s3_bucket.practice_bucket.bucket
  
}
output "iam_user_name" {
    value = [for user in aws_iam_user.team : user.name]
    description = "List of IAM user names created for the team"
  
}
output "rds_endpoint" {
    value = try(aws_db_instance.practice_db[0].endpoint, "RDS instance not created")
    description = "Endpoint of the RDS instance"
}









