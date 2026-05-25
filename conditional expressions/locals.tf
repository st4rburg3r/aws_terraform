locals {
  full_project_name = "${var.project_name}-${var.environment}"

  tags = merge(var.common_tags, {
    Name = local.full_project_name
    Env = var.environment
  })
}

locals {
  all_instance_ids = aws_instance.practice[*].id
}
