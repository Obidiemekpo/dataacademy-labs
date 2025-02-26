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
  databricks_name = "dbw-${var.environment}-${lower(replace(var.resource_group_name, "rg-", ""))}"
}

resource "azurerm_databricks_workspace" "databricks" {
  name                = local.databricks_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "standard"
  tags                = var.tags
}

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.databricks.id
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.databricks.workspace_url
} 