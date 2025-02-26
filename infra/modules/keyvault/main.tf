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

data "azurerm_client_config" "current" {}

locals {
  key_vault_name = "kv-${var.environment}-${lower(replace(var.resource_group_name, "rg-", ""))}"
}

resource "azurerm_key_vault" "key_vault" {
  name                        = local.key_vault_name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete",
    ]
  }
}

output "key_vault_id" {
  value = azurerm_key_vault.key_vault.id
}

output "key_vault_name" {
  value = azurerm_key_vault.key_vault.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.key_vault.vault_uri
} 