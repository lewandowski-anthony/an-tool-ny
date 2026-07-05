terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" version = "~> 2.0" }
    aws        = { source = "hashicorp/aws" version = "~> 5.0" }
    azurerm    = { source = "hashicorp/azurerm" version = "~> 4.0" }
    google     = { source = "hashicorp/google" version = "~> 5.0" }
  }

  # Secure Remote Backend for Preproduction state tracking
  # backend "s3" {
  #   bucket         = "company-tfstates"
  #   key            = "anthony/preprod/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "company-tflocks-preprod"
  # }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "anthony-eu-pp" # Target context shared with Qual
}

# -------------------------------------------------------------------
# Module Calls (Uncomment the active cloud stack for Preproduction)
# -------------------------------------------------------------------

# module "aws_preprod" {
#   source           = "../../modules/aws-env"
#   environment_name = "preprod"
#   context_name     = "anthony-eu-pp"
#   db_instance_class = "db.t4g.small"
# }

# module "gcp_preprod" {
#   source           = "../../modules/gcp-env"
#   environment_name = "preprod"
#   context_name     = "anthony-eu-pp"
#   db_tier          = "db-g1-small"
# }

# provider "azurerm" { features {} }
# module "azure_preprod" {
#   source           = "../../modules/azure-env"
#   environment_name = "preprod"
#   context_name     = "anthony-eu-pp"
#   sku_name         = "B_Standard_B2s"
# }