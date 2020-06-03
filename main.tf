resource "random_id" "password" {
  byte_length = 8
}

provider "credstash" {
    profile = "credstash"
    region  = var.region
}

provider "mysql" {
  endpoint = data.aws_rds_cluster.cluster.endpoint
  username = var.rds_username
  password = data.credstash_secret.password.value
}

data "credstash_secret" "password" {
  name = var.rds_password
}

data "aws_rds_cluster" "cluster" {
  cluster_identifier = var.cluster_identifier
}

resource "mysql_database" "schema" {
  name = var.schema
}

# resource "aws_ssm_parameter" "secret" {
#   name        = "/${terraform.workspace}/database/password/master"
#   description = "The parameter description"
#   type        = "SecureString"
#   value       = var.database_master_password

#   tags = {
#     app : var.github_project,
#     env : terraform.workspace,
#     repo : var.github_repository
#     project : var.project_name,
#     owner : var.project_owner,
#     email : var.project_email,
#     created_by : "terraform-rds-action"
#   }
# }