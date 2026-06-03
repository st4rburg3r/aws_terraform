#s3 bucket to store application versions for Elastic Beanstalk. 

resource "aws_s3_bucket" "app_versions" {
  bucket = "${var.app_name}-versions-twuptea"
}

#block public access to the S3 bucket to ensure that the application versions are not accessible to unauthorized users. This is a security best practice to prevent unintended exposure of sensitive data.

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.app_versions.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
}

#elastic beanstalk application to manage the application versions and environments.

resource "aws_elastic_beanstalk_application" "app" {
    name = var.app_name
    description = "Elastic Beanstalk application for blue-green deployment demo"

    tags = var.tags
  
}

#iam role for ebs ec2 instances to allow them to interact with other AWS services, such as S3 for storing application versions and CloudWatch for logging. This role will be attached to the EC2 instances in the Elastic Beanstalk environment, granting them the necessary permissions to function properly.  

resource "aws_iam_role" "eb_ec2_role" {
    name = "${var.app_name}-ec2-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })

    tags = var.tags
  
}

#attach the aws managed policy "AWSElasticBeanstalkWebTier" to the IAM role for the web tier, which provides the necessary permissions for EC2 instances in the Elastic Beanstalk environment to function properly. This policy includes permissions for actions such as reading from S3 buckets, writing logs to CloudWatch, and accessing other AWS services that are commonly used in Elastic Beanstalk applications.

# A blank identity card does nothing. These three blocks attach AWS-made permission sheets to that card. They grant the servers the rights to handle web traffic (WebTier), process background tasks (WorkerTier), or run Docker containers (MulticontainerDocker).

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
    role = aws_iam_role.eb_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

#attach the  aws managed policy for worker tier to the IAM role for worker tier, which provides the necessary permissions for EC2 instances in the Elastic Beanstalk environment to function properly. This policy includes permissions for actions such as reading from S3 buckets, writing logs to CloudWatch, and accessing other AWS services that are commonly used in Elastic Beanstalk applications.

resource "aws_iam_role_policy_attachment" "eb_worker_tier" {
    role = aws_iam_role.eb_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

#attach the aes managed policy for multicontainer docker to the IAM role for multicontainer docker, which provides the necessary permissions for EC2 instances in the Elastic Beanstalk environment to function properly. This policy includes permissions for actions such as reading from S3 buckets, writing logs to CloudWatch, and accessing other AWS services that are commonly used in Elastic Beanstalk applications.

resource "aws_iam_role_policy_attachment" "eb_multicontainer_docker" {
    role = aws_iam_role.eb_ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
  
}

#instance profile to associate the IAM role with the EC2 instances in the Elastic Beanstalk environment. This allows the EC2 instances to assume the IAM role and gain the permissions defined in the attached policies, enabling them to interact with other AWS services as needed for the application to function properly.

resource "aws_iam_instance_profile" "eb_ec2_profile" {
    name = "${var.app_name}-ec2-instance-profile"
    role = aws_iam_role.eb_ec2_role.name
  
}

#iam role for Elastic Beanstalk service to allow the Elastic Beanstalk service to interact with other AWS services on behalf of the user. This role will be assumed by the Elastic Beanstalk service when it needs to perform actions such as creating and managing resources, deploying applications, and monitoring the environment.

resource "aws_iam_role" "eb_service_role" {
    name = "${var.app_name}-service-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "elasticbeanstalk.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })

    tags = var.tags
  
}

resource "aws_iam_role_policy_attachment" "eb_service_health" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# Attach Managed Updates policy
resource "aws_iam_role_policy_attachment" "eb_service_managed_updates" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}