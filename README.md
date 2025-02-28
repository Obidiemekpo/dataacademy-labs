# DataAcademy Labs

This repository contains infrastructure as code (IaC) for provisioning Azure resources for data engineering and analytics workloads.

Prerequisites:
- Azure CLI
   Windows :
    winget install -e --id Microsoft.AzureCLI
    
   Linux:
    sudo apt-get update
    sudo apt-get install azure-cli

   MacOS:
    brew install azure-cli


- Terraform CLI
- GitHub CLI

## Infrastructure

The `infra` directory contains Terraform modules to provision the following Azure resources:

- Azure Databricks
- Azure Data Factory
- Azure SQL Database (Basic tier) - *temporarily excluded*
- Azure Key Vault
- Azure Storage Account
- Azure Data Lake Storage Gen2
- Databricks Unity Catalog and Access Connector - *temporarily disabled*

The infrastructure is designed with proper RBAC (Role-Based Access Control) to allow Azure Data Factory to access all resources securely using managed identity.

## Naming Conventions

All Azure resources follow Microsoft's recommended naming conventions with the addition of a prefix for identification:

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

The infrastructure includes a Databricks setup:

- **Workspace**: Standard Databricks workspace
- **Access Connector**: For Unity Catalog integration with Azure Storage - *temporarily disabled*
- **Unity Catalog**: Metastore, catalog, and schema for data governance - *temporarily disabled*

## Configuration

The infrastructure can be configured using a `terraform.tfvars` file in the `infra` directory. This allows you to customize:

- Resource group name
- Azure region (currently set to UK South)
- Environment (dev, test, prod)
- Prefix for resource naming (used to identify resources)
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

## Resource Tainting

This repository includes a mechanism to taint (mark for recreation) specific Terraform resources using a text file:

### Using the taint_resources.txt File

1. Edit the `taint_resources.txt` file in the repository root
2. Add the resource addresses you want to taint, one per line
3. Commit and push the changes to trigger the workflow
4. The workflow will taint the specified resources before applying changes

Example `taint_resources.txt` content:
```
module.storage.azurerm_storage_account.storage_account
```

The file will be automatically cleared after a successful apply to prevent resources from being repeatedly tainted.

### Resource Addressing

Resource addresses follow Terraform's resource addressing syntax:
- For resources in the root module: `resource_type.resource_name`
- For resources in a module: `module.module_name.resource_type.resource_name`

For more information on resource addressing, see the [Terraform documentation](https://developer.hashicorp.com/terraform/cli/state/resource-addressing).

## Automated Deployment with GitHub Actions

This repository includes GitHub Actions workflows for automated deployment and destruction of the Terraform infrastructure:

### Terraform Deploy Workflow

The deployment workflow:

1. Sets up a storage account for Terraform state if it doesn't exist
2. Initializes Terraform
3. Taints resources specified in the `taint_resources.txt` file (if any)
4. Validates the Terraform configuration
5. Plans the deployment (for pull requests)
6. Applies the changes (for pushes to main branch)
7. Clears the taint file after successful apply

### Terraform Destroy Workflow

The repository also includes an automated workflow to destroy all infrastructure resources at midnight UTC. This is useful for cost management in development environments. The workflow:

1. Runs automatically at midnight UTC (00:00) every day
2. Uses the same Terraform state storage as the deployment workflow
3. Optionally taints and recreates resources before destroying (useful for partial destroy/recreate)
4. Creates and applies a destroy plan to remove all resources
5. Creates a GitHub issue to notify about the successful destruction

The destroy workflow can also be triggered manually with a confirmation step to prevent accidental destruction.

### Setting up GitHub Actions

To use the GitHub Actions workflows:

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

3. Push changes to the `main` branch or create a pull request to trigger the deployment workflow.

### Authentication for Terraform Backend

The workflows use Service Principal authentication for the Terraform backend. The necessary credentials are extracted from the `AZURE_CREDENTIALS` secret and passed to Terraform as environment variables:

- `ARM_CLIENT_ID`: The Service Principal client ID
- `ARM_CLIENT_SECRET`: The Service Principal client secret
- `ARM_SUBSCRIPTION_ID`: The Azure subscription ID
- `ARM_TENANT_ID`: The Azure tenant ID

These environment variables are automatically set by the workflows for all Terraform commands.

### Customizing the Terraform State Storage

When manually triggering either workflow, you can specify a custom prefix for the Terraform state storage account name:

1. Go to the Actions tab in your GitHub repository
2. Select the desired workflow
3. Click "Run workflow"
4. Enter a custom prefix in the "Prefix for the Terraform state storage account name" field
5. For the destroy workflow, type "destroy" in the confirmation field
6. Click "Run workflow"

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
