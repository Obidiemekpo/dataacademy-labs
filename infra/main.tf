provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-dataacademy-prod"
}

variable "location" {
  description = "Azure region for resources"
  default     = "UK South"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  default     = "prod"
}

variable "prefix" {
  description = "Prefix to use for resource naming"
  type        = string
  default     = "da"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "DataAcademy"
    Owner       = "Data Engineering Team"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Databricks Module
module "databricks" {
  source              = "./modules/databricks"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  tags                = var.tags
}

# Data Factory Module
module "datafactory" {
  source              = "./modules/datafactory"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  tags                = var.tags
}

# SQL Module
/*
module "sql" {
  source              = "./modules/sql"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  tags                = var.tags
}
*/

# Key Vault Module
module "keyvault" {
  source              = "./modules/keyvault"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  tags                = var.tags
}

# Storage Module
module "storage" {
  source              = "./modules/storage"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  prefix              = var.prefix
  tags                = var.tags
}

# RBAC Module
module "rbac" {
  source                = "./modules/rbac"
  resource_group_name   = azurerm_resource_group.main.name
  data_factory_id       = module.datafactory.data_factory_id
  data_factory_identity = module.datafactory.data_factory_identity
  storage_account_id    = module.storage.storage_account_id
  adls_id               = module.storage.storage_account_id
  key_vault_id          = module.keyvault.key_vault_id
  sql_server_id         = "" # Commented out SQL module: module.sql.sql_server_id
  depends_on            = [module.datafactory, module.storage, module.keyvault] # Removed SQL module dependency
} 