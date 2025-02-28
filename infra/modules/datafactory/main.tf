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

resource "azurerm_data_factory" "data_factory" {
  name                = module.naming.data_factory_name
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