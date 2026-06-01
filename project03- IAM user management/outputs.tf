output "account_id" {
  value = data.aws_caller_identity.current.account_id
  
}

output "user_names" {
    value = [for user in local.users : "${user.first_name} ${user.last_name}"]
  
}

output "user_length" {
    value = length(local.users)
}

output "iam_group_assignments" {
    description = "the list of users assigned to each group"
    value = {
      accounting = aws_iam_group_membership.accounting_members.users
      corporate = aws_iam_group_membership.corporate_members.users
      representatives = aws_iam_group_membership.representatives_members.users
    }
    
}

# later we will save the user passwords in a secure vault and we will not output the passwords in terraform output, but for now we are just outputting the passwords for demonstration purposes.
#we can store the passwords in a secure vault like AWS Secrets Manager or HashiCorp Vault and then we can retrieve the passwords from the vault when needed. This way we can ensure that the passwords are stored securely and are not exposed in terraform output or in the terraform state file.#

