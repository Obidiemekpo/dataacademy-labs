# DataAcademy Labs

This repository contains infrastructure as code (IaC) for provisioning Azure resources for data engineering and analytics workloads.

## Infrastructure

The `infra` directory contains Terraform modules to provision the following Azure resources:

- Azure Databricks
- Azure Data Factory
- Azure SQL Database (Basic tier) - *temporarily excluded*
- Azure Key Vault
- Azure Storage Account
- Azure Data Lake Storage Gen2
- Databricks Unity Catalog, Access Connector, and Cluster

The infrastructure is designed with proper RBAC (Role-Based Access Control) to allow Azure Data Factory to access all resources securely using managed identity.

## Naming Conventions

All Azure resources follow Microsoft's recommended naming conventions:

- Resource Group: `rg-<environment>-<project>`
- Databricks Workspace: `dbw-<environment>-<project>`
- Databricks Access Connector: `dbw-ac-<environment>-<project>`
- Data Factory: `adf-<environment>-<project>`
- SQL Server: `sql-<environment>-<project>`
- SQL Database: `sqldb-<environment>-<project>`
- Key Vault: `kv-<environment>-<project>`
- Storage Account: `st<prefix><environment><project>` (limited to 24 characters)
- ADLS Gen2 Container: `data`

## Databricks Configuration

The infrastructure includes a comprehensive Databricks setup:

- **Workspace**: Standard Databricks workspace
- **Access Connector**: For Unity Catalog integration with Azure Storage
- **Unity Catalog**: Metastore, catalog, and schema for data governance
- **Small Cluster**: Autoscaling cluster (1-3 workers) for development and testing

## Configuration

The infrastructure can be configured using a `terraform.tfvars` file in the `infra` directory. This allows you to customize:

- Resource group name
- Azure region (currently set to UK South)
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

> **Note:** The SQL Server module is temporarily excluded from deployment. To include it, uncomment the SQL module section in `infra/main.tf`.

## Automated Deployment with GitHub Actions

This repository includes a GitHub Actions workflow for automated deployment of the Terraform infrastructure. The workflow:

1. Sets up a storage account for Terraform state if it doesn't exist
2. Initializes Terraform
3. Validates the Terraform configuration
4. Plans the deployment (for pull requests)
5. Applies the changes (for pushes to main branch)

### Setting up GitHub Actions

To use the GitHub Actions workflow:

1. Create an Azure Service Principal with Owner permissions:
   ```bash
   az ad sp create-for-rbac --name "GitHubActionsTerraform" --role Owner --scopes /subscriptions/<SUBSCRIPTION_ID> --sdk-auth
   ```

2. Add the JSON output as a GitHub secret named `AZURE_CREDENTIALS`:
   - Go to your GitHub repository
   - Navigate to Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the entire JSON output from the previous step
   - Click "Add secret"

3. Push changes to the `main` branch or create a pull request to trigger the workflow.

### Authentication for Terraform Backend

The workflow uses Service Principal authentication for the Terraform backend. The necessary credentials are extracted from the `AZURE_CREDENTIALS` secret and passed to Terraform as environment variables:

- `ARM_CLIENT_ID`: The Service Principal client ID
- `ARM_CLIENT_SECRET`: The Service Principal client secret
- `ARM_SUBSCRIPTION_ID`: The Azure subscription ID
- `ARM_TENANT_ID`: The Azure tenant ID

These environment variables are automatically set by the workflow for all Terraform commands.

### Customizing the Terraform State Storage

When manually triggering the workflow, you can specify a custom prefix for the Terraform state storage account name:

1. Go to the Actions tab in your GitHub repository
2. Select the "Terraform Deploy" workflow
3. Click "Run workflow"
4. Enter a custom prefix in the "Prefix for the Terraform state storage account name" field
5. Click "Run workflow"

The storage account name will be `st<your-prefix>tfstate`. This allows you to create separate state storage accounts for different environments or projects.

For more details, see the [GitHub Workflow documentation](.github/README.md).

## Security

The infrastructure is configured with the following security measures:

- Azure Data Factory uses managed identity for authentication
- RBAC is implemented to grant least-privilege access
- Key Vault is used for storing secrets
- SQL Server is configured with Azure AD authentication
- Databricks Access Connector uses managed identity for secure storage access

## Contributing

Please follow the standard Git workflow:

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
