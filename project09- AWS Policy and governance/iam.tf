#create an iam policy that enforces mfa for deleting s3 objects

resource "aws_iam_policy" "mfa_delete_policy" {
  name        = "mfa-delete-policy"
  description = "Policy that requires MFA for deleting S3 objects"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DenyDeleteWithoutMFA"
        Effect = "Deny"
        Action = [
          "s3:DeleteObject",
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = false
          }
        }
      }
    ]
  })
}

#iam policy to enfore encryption in transit for s3 objects

resource "aws_iam_policy" "enforce_s3_encryption_in_transit" {
  name        = "enforce-s3-encryption-in-transit"
  description = "Policy that enforces encryption in transit for S3 objects"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DenyUnencryptedTransport"
        Effect = "Deny"
        Action = [
          "s3:PutObject"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:SecureTransport" = false
          }
        }
      }
    ]
  })
  
}

#Iam policy that requires tagging for resource creation

resource "aws_iam_policy" "require_tagging_policy" {
  name        = "require-tagging-policy"
  description = "Policy that requires tagging for resource creation"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DenyResourceCreationWithoutTags"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "s3:CreateBucket",
          "rds:CreateDBInstance",
          # Add more actions for other services as needed
        ]
        Resource = "*"
        Condition = {
            Null = {
                "aws:RequestTag/Environment" = "true"
                }
        }
      },

      #require owner tag
      {
        Sid = "DenyResourceCreationWithoutOwnerTag"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "s3:CreateBucket",
          "rds:CreateDBInstance",
          # Add more actions for other services as needed
        ]
        Resource = "*"
        Condition = {
            Null = {
                "aws:RequestTag/Owner" = "true"
                }
        }

      }

    ]
  })
}

#creating an iam user for demonstration of the policies

resource "aws_iam_user" "demo_user" {
  name = "demo-user"

  tags = {
    Environment = "Demo"
    Owner       = "twuppy"
    Purpose     = "Demonstration of IAM policies"
  }
}

#attaching the policies to the demo user
resource "aws_iam_user_policy_attachment" "demo_user_mfa" {
    user = aws_iam_user.demo_user.name
    policy_arn = aws_iam_policy.mfa_delete_policy.arn
  
}
resource "aws_iam_user_policy_attachment" "demo_user_https" {
  user       = aws_iam_user.demo_user.name
  policy_arn = aws_iam_policy.enforce_s3_encryption_in_transit.arn
}

resource "aws_iam_user_policy_attachment" "demo_user_tags" {
  user       = aws_iam_user.demo_user.name
  policy_arn = aws_iam_policy.require_tagging_policy.arn
}

resource "aws_iam_user_policy_attachment" "demo_user_s3_access" {
  user       = aws_iam_user.demo_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#iam role for aws config

resource "aws_iam_role" "aws_config_role" {
  name = "aws-${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = "Demo"
    Owner       = "twuppy"
    Purpose     = "AWS Config role"
  }
}

# Attach managed policy to Config Role
resource "aws_iam_role_policy_attachment" "config_policy_attach" {
  role       = aws_iam_role.aws_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

#additional policy for config role to allow it to write to the config bucket

resource "aws_iam_role_policy" "config_s3_policy" {
    name = "config-s3-policy"
    role = aws_iam_role.aws_config_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:GetBucketAcl",
                    "s3:ListBucket"
                ]
                Resource = [
                    aws_s3_bucket.config_bucket.arn,
                    "${aws_s3_bucket.config_bucket.arn}/*"
                ]
            }
        ]
    })
  
}