locals {
  # String Functions
  full_project_name = "${var.project-name}-${var.environment}"
  upper_name        = upper(local.full_project_name)
  lower_name        = lower(local.full_project_name)
  bucket_prefix     = format("%s-logs", local.lower_name)

  #collection functions

  port_count= length(var.allowed_ports)
  first_port = element(var.allowed_ports, 0)
  last_port = element(var.allowed_ports, length(var.allowed_ports)-1)

  #merge functions
  base_tags = {
    Project     = var.project-name
    Owner       = "Trupti"
    ManagedBy   = "Terraform"
  }

  common_tags = merge(local.base_tags, {
    Environment = var.environment
  })

  #conditional + functions
  #instance_type = var.environment == "prod" ? "t3.small" : "t3.micro"

# lookup function

environment_config = {
    dev = {
        instance_type = "t3.micro"
        create_rds = false
        cpu_credits = "standard"
    }

    staging = {
        instance_type = "t3.small"
        create_rds = true
        cpu_credits = "unlimited"
    }

    prod = {
        instance_type = "t3.medium"
        create_rds = true
        cpu_credits = "unlimited"
    }
}

#using lookup function to get values from the map based on environment
current_config= lookup(local.environment_config, var.environment, local.environment_config.dev)

#collection functions in action :
instance_type = local.current_config.instance_type
should_create_rds = local.current_config.create_rds
  #uuid and substring
  short_uuid = substr(uuid(), 0, 8)

}

