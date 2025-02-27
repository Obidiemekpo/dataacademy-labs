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

locals {
  access_connector_name = "dbw-ac-${var.environment}-${lower(replace(var.resource_group_name, "rg-", ""))}"
  metastore_name        = "metastore-${var.environment}"
  catalog_name          = "landing"
  schema_name           = "landing"
  cluster_name          = "small-cluster-${var.environment}"
  # Extract the workspace numeric ID from the workspace URL
  # Example URL: adb-2501807314214598.18.azuredatabricks.net
  workspace_numeric_id = split(".", split("-", var.databricks_workspace_url)[1])[0]
}

# Create Databricks Access Connector for Unity Catalog
resource "azurerm_databricks_access_connector" "unity" {
  name                = local.access_connector_name
  resource_group_name = var.resource_group_name
  location            = var.location
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

# Grant Storage Blob Data Contributor role to the Access Connector
resource "azurerm_role_assignment" "access_connector_storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity.identity[0].principal_id
}

# Wait for role assignment to propagate
resource "time_sleep" "wait_for_role_assignment" {
  depends_on      = [azurerm_role_assignment.access_connector_storage]
  create_duration = "30s"
}

# Create Unity Catalog Metastore
resource "databricks_metastore" "this" {
  name = local.metastore_name
  storage_root = format(
    "abfss://unity-catalog@%s.dfs.core.windows.net/",
    var.storage_account_name
  )
  owner      = "account users"
  depends_on = [time_sleep.wait_for_role_assignment]
}

# Assign Metastore to Workspace
resource "databricks_metastore_assignment" "this" {
  metastore_id = databricks_metastore.this.id
  workspace_id = local.workspace_numeric_id
}

# Create Unity Catalog
resource "databricks_catalog" "landing" {
  metastore_id = databricks_metastore.this.id
  name         = local.catalog_name
  comment      = "Landing catalog for raw data"
  properties = {
    purpose = "landing_zone"
  }
  depends_on = [databricks_metastore_assignment.this]
}

# Create Schema in the Catalog
resource "databricks_schema" "landing" {
  catalog_name = databricks_catalog.landing.name
  name         = local.schema_name
  comment      = "Landing schema for raw data"
  properties = {
    kind = "landing"
  }
}

# Create a small Databricks cluster
resource "databricks_cluster" "small_cluster" {
  cluster_name            = local.cluster_name
  spark_version           = "13.3.x-scala2.12"
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = 20

  autoscale {
    min_workers = 1
    max_workers = 3
  }

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
    "Environment"   = var.environment
  }
}

output "access_connector_id" {
  value = azurerm_databricks_access_connector.unity.id
}

output "metastore_id" {
  value = databricks_metastore.this.id
}

output "catalog_id" {
  value = databricks_catalog.landing.id
}

output "schema_id" {
  value = databricks_schema.landing.id
}

output "cluster_id" {
  value = databricks_cluster.small_cluster.id
} 