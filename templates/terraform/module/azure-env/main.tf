resource "azurerm_resource_group" "rg" {
  name     = "rg-anthony-${var.environment_name}"
  location = var.location
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.environment_name == "qual" ? "anthony-qual" : "anthony"
    labels = {
      context = var.context_name
      env     = var.environment_name
    }
  }
}

resource "azurerm_postgresql_flexible_server" "server" {
  name                   = "server-anthony-${var.environment_name}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "16"
  administrator_login    = "psqladmin"
  administrator_password = "H@rdToGuessPassword123!"
  sku_name               = var.sku_name
  storage_mb             = 32768
}

resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = "db_anthony_${var.environment_name}"
  server_id = azurerm_postgresql_flexible_server.server.id
  collation = "en_US.utf8"
  charset   = "utf8"
}