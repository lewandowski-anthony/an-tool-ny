terraform {
  required_version = ">= 1.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# -------------------------------------------------------------------
# 1. Local Kubernetes Cluster Creation
# -------------------------------------------------------------------
resource "kind_cluster" "anthony_cluster" {
  name            = "anthony-cluster"
  kubeconfig_path = expanduser("~/.kube/config")
  wait_for_ready  = true
}

# -------------------------------------------------------------------
# 2. Providers configuration
# -------------------------------------------------------------------
provider "kubernetes" {
  config_path    = kind_cluster.anthony_cluster.kubeconfig_path
  config_context = "kind-anthony-cluster"
}

provider "azurerm" {
  features {}
}

# Azure Resource Group obligatoire pour structurer l'infra
resource "azurerm_resource_group" "rg" {
  name     = "rg-anthony-environments"
  location = "westeurope"
}

# -------------------------------------------------------------------
# 3. Preprod context : anthony-eu-pp
# -------------------------------------------------------------------

resource "kubernetes_namespace" "pp_anthony" {
  metadata {
    name = "anthony"
    labels = {
      context = "anthony-eu-pp"
      env     = "preprod"
    }
  }
}

resource "kubernetes_namespace" "pp_anthony_qual" {
  metadata {
    name = "anthony-qual"
    labels = {
      context = "anthony-eu-pp"
      env     = "qual"
    }
  }
}

# Serveur Flexible PostgreSQL pour la Preprod
resource "azurerm_postgresql_flexible_server" "server_pp" {
  name                   = "server-anthony-pp"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = "H@rdToGuessPassword123!"
  sku_name               = "B_Standard_B1ms" # Tier Burstable pas cher pour le dev
  storage_mb             = 32768
}

resource "azurerm_postgresql_flexible_server_database" "db_pp_anthony" {
  name      = "db_anthony_pp"
  server_id = azurerm_postgresql_flexible_server.server_pp.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Serveur Flexible PostgreSQL pour la Qual
resource "azurerm_postgresql_flexible_server" "server_qual" {
  name                   = "server-anthony-qual"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = "H@rdToGuessPassword123!"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
}

resource "azurerm_postgresql_flexible_server_database" "db_pp_anthony_qual" {
  name      = "db_anthony_qual"
  server_id = azurerm_postgresql_flexible_server.server_qual.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# -------------------------------------------------------------------
# 4. Production context : anthony-eu-pr
# -------------------------------------------------------------------

resource "kubernetes_namespace" "pr_anthony" {
  metadata {
    name = "anthony"
    labels = {
      context = "anthony-eu-pr"
      env     = "prod"
    }
  }
}

# Postgres server
resource "azurerm_postgresql_flexible_server" "server_pr" {
  name                   = "server-anthony-pr"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = "UltraSecureProdPassword987!"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
}

resource "azurerm_postgresql_flexible_server_database" "db_pr_anthony" {
  name      = "db_anthony_pr"
  server_id = azurerm_postgresql_flexible_server.server_pr.id
  collation = "en_US.utf8"
  charset   = "utf8"
}