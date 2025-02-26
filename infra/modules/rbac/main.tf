variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "data_factory_id" {
  description = "ID of the Data Factory"
  type        = string
}

variable "data_factory_identity" {
  description = "Principal ID of the Data Factory's managed identity"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the Storage Account"
  type        = string
}

variable "adls_id" {
  description = "ID of the ADLS Gen2 filesystem"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "sql_server_id" {
  description = "ID of the SQL Server"
  type        = string
}

# Get current client config for tenant ID
data "azurerm_client_config" "current" {}

# Grant Data Factory Managed Identity Contributor access to Storage Account
resource "azurerm_role_assignment" "df_storage_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.data_factory_identity
}

# Grant Data Factory Managed Identity Contributor access to ADLS Gen2
resource "azurerm_role_assignment" "df_adls_contributor" {
  scope                = var.adls_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.data_factory_identity
}

# Grant Data Factory Managed Identity access to Key Vault secrets
resource "azurerm_key_vault_access_policy" "df_key_vault_access" {
  key_vault_id = var.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.data_factory_identity

  secret_permissions = [
    "Get", "List",
  ]
}

# Note: SQL Server admin access is handled through Azure AD integration
# This would typically be done through the Azure Portal or using a different resource
# For now, we'll use a comment to document this requirement
# The azurerm_mssql_server_active_directory_administrator resource is not available in the current provider version
