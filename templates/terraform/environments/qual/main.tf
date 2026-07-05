terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" version = "~> 2.0" }
    aws        = { source = "hashicorp/aws" version = "~> 5.0" }
    azurerm    = { source = "hashicorp/azurerm" version = "~> 4.0" }
    google     = { source = "hashicorp/google" version = "~> 5.0" }
  }

  # Secure Remote Backend for Qualification state tracking
  # backend "s3" {
  #   bucket         = "company-tfstates"
  #   key            = "anthony/qual/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "company-tflocks-qual"
  # }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "anthony-eu-pp" # Target context shared with Preprod
}

# -------------------------------------------------------------------
# Module Calls (Uncomment the active cloud stack for Qualification)
# -------------------------------------------------------------------

# module "aws_qual" {
#   source           = "../../modules/aws-env"
#   environment_name = "qual"
#   context_name     = "anthony-eu-pp"
#   db_instance_class = "db.t4g.micro"
# }

# module "gcp_qual" {
#   source           = "../../modules/gcp-env"
#   environment_name = "qual"
#   context_name     = "anthony-eu-pp"
#   db_tier          = "db-f1-micro"
# }

# provider "azurerm" { features {} }
# module "azure_qual" {
#   source           = "../../modules/azure-env"
#   environment_name = "qual"
#   context_name     = "anthony-eu-pp"
#   sku_name         = "B_Standard_B1ms"
# }