#uploads the application zip file to an S3 bucket, making it available for deployment to Elastic Beanstalk. The bucket is specified by aws_s3_bucket.app_versions.id, and the key for the object is "app-v1.zip". The source parameter points to the local path of the application zip file, and the etag is calculated using the filemd5 function to ensure that the correct version of the file is uploaded. Additionally, tags can be added to the S3 object using the var.tags variable.

resource "aws_s3_object" "app_v1" {
  bucket = aws_s3_bucket.app_versions.id
  key    = "app-v1.zip"
  source = "${path.module}/app-v1/app-v1.zip"
  etag   = filemd5("${path.module}/app-v1/app-v1.zip")

  tags = var.tags
}

resource "aws_elastic_beanstalk_application_version" "v1" {
    name = "${var.app_name}-v1"
    application = aws_elastic_beanstalk_application.app.name
    description = "Version 1 of the application"
    bucket = aws_s3_bucket.app_versions.id
    key = aws_s3_object.app_v1.key

    tags = var.tags
  
}

#blue environment is created using the application version v1. This environment will serve as the initial deployment of the application, allowing you to test and validate the application before deploying it to production.

resource "aws_elastic_beanstalk_environment" "blue" {
    name = "${var.app_name}-blue"
    application = aws_elastic_beanstalk_application.app.name
    solution_stack_name = var.solution_stack_name
    tier = "WebServer"
    version_label = aws_elastic_beanstalk_application_version.v1.name
    wait_for_ready_timeout = "60m"
    # IAM Settings

    setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.name
  }

  # Instance Settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # Environment Type (Load Balanced)
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # Auto Scaling Settings
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "2"
  }

  # Health Reporting
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  # Platform Settings
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  # Environment Variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ENVIRONMENT"
    value     = "blue"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "VERSION"
    value     = "1.0"
  }

  # Deployment Policy
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "50"
  }

  # Managed Updates
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "false"
  }

  tags = merge(
    var.tags,
    {
      Environment = "blue"
      Role        = "production"
    }
  )
}
  
