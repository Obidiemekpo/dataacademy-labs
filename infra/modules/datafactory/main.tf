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
  data_factory_name = "adf-${var.environment}-${lower(replace(var.resource_group_name, "rg-", ""))}"
}

resource "azurerm_data_factory" "data_factory" {
  name                = local.data_factory_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

output "data_factory_id" {
  value = azurerm_data_factory.data_factory.id
}

output "data_factory_identity" {
  value = azurerm_data_factory.data_factory.identity[0].principal_id
} 