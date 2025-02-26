# DataAcademy Labs

This repository contains infrastructure as code (IaC) for provisioning Azure resources for data engineering and analytics workloads.

## Infrastructure

The `infra` directory contains Terraform modules to provision the following Azure resources:

- Azure Databricks
- Azure Data Factory
- Azure SQL Database (Basic tier)
- Azure Key Vault
- Azure Storage Account
- Azure Data Lake Storage Gen2

The infrastructure is designed with proper RBAC (Role-Based Access Control) to allow Azure Data Factory to access all resources securely using managed identity.

## Naming Conventions

All Azure resources follow Microsoft's recommended naming conventions:

- Resource Group: `rg-<environment>-<project>`
- Databricks Workspace: `dbw-<environment>-<project>`
- Data Factory: `adf-<environment>-<project>`
- SQL Server: `sql-<environment>-<project>`
- SQL Database: `sqldb-<environment>-<project>`
- Key Vault: `kv-<environment>-<project>`
- Storage Account: `st<prefix><environment><project>` (limited to 24 characters)
- ADLS Gen2 Container: `data`

## Configuration

The infrastructure can be configured using a `terraform.tfvars` file in the `infra` directory. This allows you to customize:

- Resource group name
- Azure region
- Environment (dev, test, prod)
- Prefix for resource naming
- Tags for all resources

## Getting Started

1. Clone this repository
2. Navigate to the `infra` directory
3. Create or modify the `terraform.tfvars` file with your desired configuration
4. Initialize Terraform:
   ```
   terraform init
   ```
5. Plan the deployment:
   ```
   terraform plan -out=tfplan
   ```
6. Apply the deployment:
   ```
   terraform apply tfplan
   ```

## Security

The infrastructure is configured with the following security measures:

- Azure Data Factory uses managed identity for authentication
- RBAC is implemented to grant least-privilege access
- Key Vault is used for storing secrets
- SQL Server is configured with Azure AD authentication

## Contributing

Please follow the standard Git workflow:

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
