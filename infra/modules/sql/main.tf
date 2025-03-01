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

variable "prefix" {
  description = "Prefix to use for resource naming"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

module "naming" {
  source              = "../naming"
  prefix              = var.prefix
  environment         = var.environment
  resource_group_name = var.resource_group_name
}

locals {
  sql_admin_username = "sqladmin"
  sql_admin_password = "P@ssw0rd1234!" # In production, use Azure Key Vault to store this securely
}

resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = module.naming.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = local.sql_admin_username
  administrator_login_password = random_password.sql_password.result
  minimum_tls_version          = "1.2"
  tags                         = var.tags
}

resource "azurerm_mssql_database" "sql_database" {
  name      = module.naming.sql_database_name
  server_id = azurerm_mssql_server.sql_server.id
  tags      = var.tags

  # Serverless configuration
  sku_name    = "GP_S_Gen5_1"
  max_size_gb = 32

  # Auto-pause settings for serverless
  auto_pause_delay_in_minutes = 20
  min_capacity                = 0.5

  # Zone redundancy for high availability
  zone_redundant = false
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

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "sql_connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_database.name};Persist Security Info=False;User ID=${local.sql_admin_username};Password=${random_password.sql_password.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive = true
} 