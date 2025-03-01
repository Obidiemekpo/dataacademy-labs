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

variable "databricks_workspace_id" {
  description = "ID of the Databricks workspace"
  type        = string
}

variable "databricks_workspace_url" {
  description = "URL of the Databricks workspace"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the Storage Account for Unity Catalog metastore"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Storage Account for Unity Catalog metastore"
  type        = string
}

variable "prefix" {
  description = "Prefix to use for resource naming"
  type        = string
  default     = "da"
}

module "naming" {
  source              = "../naming"
  prefix              = var.prefix
  environment         = var.environment
  resource_group_name = var.resource_group_name
}

locals {
  metastore_name = "metastore-${var.prefix}-${var.environment}"
  catalog_name   = "landing-${var.prefix}"
  schema_name    = "landing-${var.prefix}"
  # Extract the workspace numeric ID from the workspace URL
  # Example URL: adb-2501807314214598.18.azuredatabricks.net
  workspace_numeric_id = split(".", split("-", var.databricks_workspace_url)[1])[0]
}

// Commenting out Metastore and Access Connector resources to disable their creation

// # Create Databricks Access Connector for Unity Catalog
// resource "azurerm_databricks_access_connector" "unity" {
//   name                = module.naming.databricks_access_connector_name
//   resource_group_name = var.resource_group_name
//   location            = var.location
//   identity {
//     type = "SystemAssigned"
//   }
//   tags = var.tags
// }

// # Grant Storage Blob Data Contributor role to the Access Connector
// resource "azurerm_role_assignment" "access_connector_storage" {
//   scope                = var.storage_account_id
//   role_definition_name = "Storage Blob Data Contributor"
//   principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
// }

// # Wait for role assignment to propagate
// resource "time_sleep" "wait_for_role_assignment" {
//   depends_on      = [azurerm_role_assignment.access_connector_storage]
//   create_duration = "30s"
// }

// # Create Unity Catalog Metastore
// resource "databricks_metastore" "this" {
//   name = local.metastore_name
//   storage_root = format(
//     "abfss://unity-catalog@%s.dfs.core.windows.net/",
//     var.storage_account_name
//   )
//   owner      = "account users"
//   depends_on = [time_sleep.wait_for_role_assignment]
// }

// Commenting out outputs for disabled resources

// output "access_connector_id" {
//   value = azurerm_databricks_access_connector.unity.id
// }

// output "metastore_id" {
//   value = databricks_metastore.this.id
// } 