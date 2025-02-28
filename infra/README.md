# Azure Data Platform Infrastructure

This directory contains Terraform modules to provision Azure resources for a data platform, including:

- Azure Databricks
- Azure Data Factory
- Azure Key Vault
- Azure Storage Account
- Azure Data Lake Storage Gen2
- Azure SQL Database (Basic tier) - *temporarily excluded*
- Databricks Unity Catalog and Access Connector - *temporarily disabled*

## Module Structure

The infrastructure is organized into the following modules:

- `databricks`: Provisions an Azure Databricks workspace
- `databricks_config`: Configures Databricks with Unity Catalog and Access Connector - *temporarily disabled*
- `datafactory`: Provisions an Azure Data Factory instance with system-assigned managed identity
- `keyvault`: Provisions an Azure Key Vault for storing secrets
- `storage`: Provisions an Azure Storage Account with ADLS Gen2 capabilities
- `rbac`: Configures Role-Based Access Control (RBAC) for the resources
- `sql`: Provisions an Azure SQL Server and Database with Basic tier (lowest free tier) - *temporarily excluded*

## Naming Conventions

All resources follow Azure's recommended naming conventions with the addition of a prefix for identification:

- Resource Group: `rg-<environment>-<project>`
- Databricks Workspace: `dbw-<prefix>-<environment>-<project>`
- Databricks Access Connector: `dbw-ac-<prefix>-<environment>-<project>`
- Data Factory: `adf-<prefix>-<environment>-<project>`
- SQL Server: `sql-<prefix>-<environment>-<project>`
- SQL Database: `sqldb-<prefix>-<environment>-<project>`
- Key Vault: `kv-<prefix>-<environment>-<project>`
- Storage Account: `st<short_prefix><environment><project>` (limited to 24 characters)
- ADLS Gen2 Container: `data-<prefix>`

For resources with length constraints (like storage accounts), a shortened prefix is used:
- If the prefix is 4 characters or less, the full prefix is used
- If the prefix is longer than 4 characters, the first 2 and last 2 characters are used (e.g., "dataacademy" becomes "damy")

## Databricks Configuration

The `databricks_config` module is configured to set up the following components (currently disabled):

- **Access Connector**: Creates an Azure Databricks Access Connector with a system-assigned managed identity
- **RBAC**: Grants the Access Connector Storage Blob Data Contributor access to the ADLS Gen2 storage
- **Unity Catalog Metastore**: Configures a metastore using the ADLS Gen2 storage
- **Catalog**: Creates a Unity Catalog called "landing"
- **Schema**: Creates a schema called "landing" within the catalog

## RBAC Configuration

The RBAC module configures the following permissions:

- Data Factory has Storage Blob Data Contributor access to the Storage Account
- Data Factory has Storage Blob Data Owner access to the Storage Account (for ADLS Gen2)
- Data Factory has access to Key Vault secrets
- Databricks Access Connector has Storage Blob Data Contributor access to the Storage Account

Note: 
- SQL Server admin access needs to be configured manually through the Azure Portal or using a different approach.
- For ADLS Gen2 permissions, we assign roles at the Storage Account level rather than the filesystem level, as the filesystem ID is not a valid scope for role assignments.

## Configuration with terraform.tfvars

The infrastructure can be configured using a `terraform.tfvars` file. Here's an example:

```hcl
resource_group_name = "rg-dataacademy-prod"
location            = "UK South"
environment         = "prod"
prefix              = "dataacademy"
tags = {
  Environment = "Production"
  Project     = "DataAcademy"
  Owner       = "Data Engineering Team"
}
```

## Variables

The main variables that can be configured are:

- `resource_group_name`: Name of the resource group
- `location`: Azure region for resources
- `environment`: Environment (dev, test, prod)
- `prefix`: Prefix to use for resource naming (used to identify resources)
- `tags`: Tags to apply to all resources

## Usage

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Plan the deployment:
   ```
   terraform plan -out=tfplan
   ```

3. Apply the deployment:
   ```
   terraform apply tfplan
   ```

4. Destroy the resources when no longer needed:
   ```
   terraform destroy
   ```

## Notes

- Storage account names must be between 3-24 characters, lowercase letters and numbers only. The module automatically truncates the name if it exceeds 24 characters.
- The SQL Server module is temporarily excluded from deployment. To include it, uncomment the SQL module section in `main.tf`.
- ADLS Gen2 permissions are assigned at the Storage Account level, not at the filesystem level.
- The Databricks provider requires authentication. When running locally, you may need to configure authentication using the Databricks CLI or environment variables. 