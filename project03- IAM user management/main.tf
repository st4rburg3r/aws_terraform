resource "aws_iam_user" "users" {
    for_each = { for user in local.users : user.first_name => user }
    name     = lower("${substr(each.value.first_name, 0, 1)}${each.value.last_name}")
  
    path     = "/users/"
    tags = {
        Name       = "${each.value.first_name} ${each.value.last_name}"
        Role       = each.value.job_title
        Department = each.value.department
    }
}

#then we need to set up aws iam user login profile because without that user will not be able to login to aws console, " and we will set the password reset required to true, so that user will have to reset the password after first login.

resource "aws_iam_user_login_profile" "user_login_profile" {
    for_each = aws_iam_user.users
    user     = each.value.name  
    password_length = 12
    password_reset_required = true

    lifecycle {
      ignore_changes = [ password_reset_required , password_length ]

    }
  
}
#creating the secrets manager container to store the user passwords, we will store the user passwords in the secrets manager and we will retrieve the passwords from the secrets manager when needed, this way we can ensure that the passwords are stored securely and are not exposed in terraform output or in the terraform state file.
resource "aws_secretsmanager_secret" "user_password" {
    for_each = aws_iam_user.users
    name = "${each.value.name}_password"
    description = "Password for ${each.value.name}"
    recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "user_password_version" {
    for_each = aws_iam_user.users
    secret_id = aws_secretsmanager_secret.user_password[each.key].id
    secret_string = aws_iam_user_login_profile.user_login_profile[each.key].password
}

resource "aws_iam_group" "accounting" {
    name = "accounting"
    path = "/groups/"
  
}

resource "aws_iam_group" "corporate" {
    name = "corporate"
    path = "/groups/"
  
}

resource "aws_iam_group" "representatives" {
    name = "representatives"
    path = "/groups/"
  
}

resource "aws_iam_policy" "enforce_mfa" {
  name        = "EnforceMFA"
  description = "Blocks all AWS actions unless the user has authenticated with MFA."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowUsersToManageTheirOwnMFA"
        Effect    = "Allow"
        Action    = [
          "iam:*VirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyEverythingExceptMFAActionsIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:*VirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ChangePassword"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

#this is association of users to groups, we will associate users to groups based on their department, so that we can manage the permissions of users based on their department.
resource "aws_iam_group_membership" "accounting_members" {
    name = "accounting-group-membership"
    group = aws_iam_group.accounting.name
    users = [for user in aws_iam_user.users : user.name if user.tags["Department"] == "Accounting"] 
}

# Add users to the Corporate group
resource "aws_iam_group_membership" "corporate_members" {
  name  = "corporate-group-membership"
  group = aws_iam_group.corporate.name

  users = [for user in aws_iam_user.users : user.name if user.tags["Department"] == "Corporate"] 
}

# Add users to the Representatives group
resource "aws_iam_group_membership" "representatives_members" {
  name  = "representatives-group-membership"
  group = aws_iam_group.representatives.name

  users = [for user in aws_iam_user.users : user.name if user.tags["Role"] == "Sales Representative"] 
  
}

# 1. Managers get Full Admin Access (AWS Managed Policy)
resource "aws_iam_group_policy_attachment" "accounting_admin" {
  for_each = {
    "administrator-access" = "arn:aws:iam::aws:policy/AdministratorAccess"
    "enforce-mfa" = aws_iam_policy.enforce_mfa.arn
  }
    group      = aws_iam_group.accounting.name
    policy_arn = each.value
    }

# 2. Corporate gets Read-Only Access (AWS Managed Policy)
resource "aws_iam_group_policy_attachment" "corporate_readonly" {
  
  for_each = {
    "readonly-access" = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    "enforce-mfa" = aws_iam_policy.enforce_mfa.arn
}
    group      = aws_iam_group.corporate.name
    policy_arn = each.value

  
}

# 3. Representatives get Power-User Access (Everything except IAM/Billing)
resource "aws_iam_group_policy_attachment" "representatives_poweruser" {
  for_each = {
    "poweruser-access" = "arn:aws:iam::aws:policy/PowerUserAccess"
    "enforce-mfa" = aws_iam_policy.enforce_mfa.arn
  }

    group      = aws_iam_group.representatives.name
    policy_arn = each.value
}