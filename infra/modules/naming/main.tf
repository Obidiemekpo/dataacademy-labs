variable "prefix" {
  description = "Prefix to use for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

locals {
  # Extract the project name from the resource group name (remove "rg-" prefix)
  project_name = lower(replace(var.resource_group_name, "rg-", ""))
  
  # For resources with length constraints, create a shortened prefix
  # Take first two and last two characters of the prefix
  short_prefix = length(var.prefix) <= 4 ? var.prefix : "${substr(var.prefix, 0, 2)}${substr(var.prefix, length(var.prefix) - 2, 2)}"
  
  # For Key Vault, ensure the name is between 3-24 characters
  key_vault_name_full = "kv-${var.prefix}-${var.environment}-${local.project_name}"
  key_vault_name = length(local.key_vault_name_full) <= 24 ? local.key_vault_name_full : "kv-${local.short_prefix}-${var.environment}-${substr(local.project_name, 0, 10)}"
}

# Function to generate resource names with prefix
output "databricks_name" {
  description = "Name for Azure Databricks workspace"
  value       = "dbw-${var.prefix}-${var.environment}-${local.project_name}"
}

output "databricks_access_connector_name" {
  description = "Name for Azure Databricks Access Connector"
  value       = "dbw-ac-${var.prefix}-${var.environment}-${local.project_name}"
}

output "data_factory_name" {
  description = "Name for Azure Data Factory"
  value       = "adf-${var.prefix}-${var.environment}-${local.project_name}"
}

output "key_vault_name" {
  description = "Name for Azure Key Vault (max 24 chars)"
  value       = local.key_vault_name
}

output "sql_server_name" {
  description = "Name for Azure SQL Server"
  value       = "sql-${var.prefix}-${var.environment}-${local.project_name}"
}

output "sql_database_name" {
  description = "Name for Azure SQL Database"
  value       = "sqldb-${var.prefix}-${var.environment}-${local.project_name}"
}

# Storage account has a 24 character limit
output "storage_account_name" {
  description = "Name for Azure Storage Account (max 24 chars)"
  value       = lower(substr("st${local.short_prefix}${var.environment}${replace(local.project_name, "-", "")}", 0, 24))
}

output "container_name" {
  description = "Name for ADLS Gen2 container"
  value       = "data-${var.prefix}"
} 