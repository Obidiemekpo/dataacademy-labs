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

resource "azurerm_storage_account" "storage_account" {
  name                     = module.naming.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Hierarchical namespace for ADLS Gen2
  tags                     = var.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "adls" {
  name               = module.naming.container_name
  storage_account_id = azurerm_storage_account.storage_account.id
}

output "storage_account_id" {
  value = azurerm_storage_account.storage_account.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "adls_id" {
  value = azurerm_storage_account.storage_account.id
}

output "adls_name" {
  value = azurerm_storage_data_lake_gen2_filesystem.adls.name
} 