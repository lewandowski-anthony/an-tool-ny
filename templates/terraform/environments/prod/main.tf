terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" version = "~> 2.0" }
    aws        = { source = "hashicorp/aws" version = "~> 5.0" }
    azurerm    = { source = "hashicorp/azurerm" version = "~> 4.0" }
    google     = { source = "hashicorp/google" version = "~> 5.0" }
  }

  # Strict Production Remote Backend Isolation with state locking mechanisms
  # backend "s3" {
  #   bucket         = "company-tfstates-prod"
  #   key            = "anthony/prod/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "company-tflocks-prod"
  # }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "anthony-eu-pr" # Target context strictly reserved for Production
}

# -------------------------------------------------------------------
# Module Calls (Uncomment the active cloud stack for Production)
# -------------------------------------------------------------------

# module "aws_prod" {
#   source           = "../../modules/aws-env"
#   environment_name = "prod"
#   context_name     = "anthony-eu-pr"
#   db_instance_class = "db.m6g.large" # Production-grade compute resource
# }

# module "gcp_prod" {
#   source           = "../../modules/gcp-env"
#   environment_name = "prod"
#   context_name     = "anthony-eu-pr"
#   db_tier          = "db-custom-2-7500" # Production-grade enterprise tier
# }

# provider "azurerm" { features {} }
# module "azure_prod" {
#   source           = "../../modules/azure-env"
#   environment_name = "prod"
#   context_name     = "anthony-eu-pr"
#   sku_name         = "GP_Standard_D2ds_v5" # General Purpose production instance
# }