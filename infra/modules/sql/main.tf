variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

locals {
  sql_server_name     = "sql-${var.environment}-${lower(replace(var.resource_group_name, "rg-", ""))}"
  sql_database_name   = "sqldb-${var.environment}-${lower(replace(var.resource_group_name, "rg-", ""))}"
  sql_admin_username  = "sqladmin"
  sql_admin_password  = "P@ssw0rd1234!" # In production, use Azure Key Vault to store this securely
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = local.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = local.sql_admin_username
  administrator_login_password = local.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.tags
}

resource "azurerm_mssql_database" "sql_database" {
  name                = local.sql_database_name
  server_id           = azurerm_mssql_server.sql_server.id
  sku_name            = "Basic" # Lowest free tier
  max_size_gb         = 2
  tags                = var.tags
}

# Allow Azure services to access the SQL server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

output "sql_server_id" {
  value = azurerm_mssql_server.sql_server.id
}

output "sql_server_name" {
  value = azurerm_mssql_server.sql_server.name
}

output "sql_database_id" {
  value = azurerm_mssql_database.sql_database.id
}

output "sql_database_name" {
  value = azurerm_mssql_database.sql_database.name
} 