# GitHub Workflow for Terraform Deployment

This directory contains GitHub workflow configurations for automating the deployment of Terraform infrastructure.

## Workflow: Terraform Deploy

The `terraform-deploy.yml` workflow automates the deployment of Azure resources using Terraform. It performs the following steps:

1. Sets up a storage account for Terraform state if it doesn't exist
2. Initializes Terraform
3. Taints resources specified in the `taint_resources.txt` file (if any)
4. Validates the Terraform configuration
5. Plans the deployment (for pull requests)
6. Applies the changes (for pushes to main branch)
7. Clears the taint file after successful apply

## Workflow: Terraform Destroy at Midnight

The `terraform-destroy.yml` workflow automates the destruction of all Azure resources at midnight UTC. It performs the following steps:

1. Sets up the same Terraform state storage configuration
2. Initializes Terraform with the existing state
3. Optionally taints and recreates resources before destroying (useful for partial destroy/recreate)
4. Creates a destroy plan
5. Applies the destroy plan to remove all resources
6. Creates a GitHub issue to notify about the successful destruction

This workflow can be triggered in two ways:
- Automatically at midnight UTC (00:00) every day via a cron schedule
- Manually through the GitHub Actions interface with a confirmation

### Manual Trigger with Confirmation

To manually trigger the destroy workflow:

1. Go to the Actions tab in your GitHub repository
2. Select the "Terraform Destroy at Midnight" workflow
3. Click "Run workflow"
4. Enter a custom prefix for the storage account name if needed
5. Type "destroy" in the confirmation field to confirm the destruction
6. Optionally check "Taint resources before destroying" if you want to recreate specific resources before destroying
7. Click "Run workflow"

The confirmation step is a safety measure to prevent accidental destruction of resources.

## Resource Prefix Generation

Both workflows include automatic resource prefix generation based on the repository owner's name:

1. If no resource prefix is provided or the default "da" is used:
   - The workflow extracts the repository owner's name
   - Takes the first letter and last two letters of the name
   - For example, if the repository owner is "johndoe", the prefix would be "joe"
   
2. This ensures unique resource naming across different deployments and helps prevent naming conflicts when multiple people deploy the infrastructure from their own repositories.

3. You can always override this by explicitly providing a resource prefix when triggering the workflow manually.

## Resource Tainting

The workflows include a mechanism to taint (mark for recreation) specific Terraform resources using a text file:

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

### Tainting Before Destroy

The destroy workflow includes an option to taint resources before destroying. This is useful when you want to:
1. Recreate specific resources with updated configurations
2. Test the recreation of resources before a full destruction
3. Fix resources that are in a bad state before destroying the entire infrastructure

When this option is selected, the workflow will:
1. Taint the resources specified in the `taint_resources.txt` file
2. Apply the changes to recreate the tainted resources
3. Clear the taint file
4. Proceed with the destroy operation

## Prerequisites

To use this workflow, you need to set up the following:

### 1. Service Principal

Create an Azure Service Principal with Owner permissions on the subscription:

```bash
az ad sp create-for-rbac --name "GitHubActionsTerraform" --role Owner --scopes /subscriptions/<SUBSCRIPTION_ID> --sdk-auth
```

The command will output a JSON object that looks like this:

```json
{
  "clientId": "<GUID>",
  "clientSecret": "<STRING>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### 2. GitHub Secret

Add this JSON as a GitHub secret named `AZURE_CREDENTIALS`:

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the entire JSON output from the previous step
6. Click "Add secret"

### 3. Databricks Provider Configuration (Optional)

For the Databricks provider, you'll need to configure authentication. The workflow is set up to use environment variables:

- `DATABRICKS_HOST`: The URL of your Databricks workspace
- `DATABRICKS_TOKEN`: A Databricks personal access token

These are currently left empty in the workflow file, as the Databricks workspace is created as part of the Terraform deployment. For a complete deployment that includes Unity Catalog and cluster configuration, you'll need to:

1. Run the initial deployment to create the Databricks workspace
2. Generate a Databricks token
3. Update the workflow with these values or add them as GitHub secrets

## Terraform State Storage

The workflow automatically creates a storage account for Terraform state if it doesn't exist. The storage account details are:

- Resource Group: `rg-terraform-state`
- Storage Account: `st<prefix>tfstate` (where `<prefix>` is customizable)
- Container: `tfstate`
- Location: `uksouth`

### Authentication for Terraform Backend

The workflow uses Service Principal authentication for the Terraform backend. The necessary credentials are extracted from the `AZURE_CREDENTIALS` secret and passed to Terraform as environment variables:

- `ARM_CLIENT_ID`: The Service Principal client ID
- `ARM_CLIENT_SECRET`: The Service Principal client secret
- `ARM_SUBSCRIPTION_ID`: The Azure subscription ID
- `ARM_TENANT_ID`: The Azure tenant ID

These environment variables are automatically set by the workflow for all Terraform commands (init, validate, plan, apply).

### Customizing the Storage Account Name

When manually triggering the workflow, you can specify a custom prefix for the storage account name:

1. Go to the Actions tab in your GitHub repository
2. Select the "Terraform Deploy" workflow
3. Click "Run workflow"
4. Enter a custom prefix in the "Prefix for the Terraform state storage account name" field
5. Click "Run workflow"

The storage account name will be `st<your-prefix>tfstate`. The default prefix is `dataacademy` if none is specified.

**Note:** Storage account names must:
- Be between 3-24 characters in length
- Use only lowercase letters and numbers
- Be globally unique across Azure

## Customization

You can customize the workflow by modifying the following files:

- `.github/workflows/terraform-deploy.yml`: The main workflow file
- `.github/workflows/terraform-destroy.yml`: The destroy workflow file
- `.github/scripts/setup_terraform_state.sh`: Script to set up the Terraform state storage account
- `.github/scripts/taint_resources.sh`: Script to taint resources based on the taint_resources.txt file
- `taint_resources.txt`: File containing resources to taint

## Troubleshooting

If you encounter issues with the workflow:

1. Check the workflow run logs in GitHub Actions
2. Verify that the Service Principal has the correct permissions
3. Ensure that the `AZURE_CREDENTIALS` secret is correctly formatted
4. Check if the storage account name is globally unique
5. If you get an error about the storage account name being too long or containing invalid characters, try a shorter or simpler prefix

### Common Issues

#### Backend Authentication Error

If you encounter an error like:
```
Error: Error building ARM Config: Authenticating using the Azure CLI is only supported as a User (not a Service Principal).
```

This means Terraform is trying to use the Azure CLI authentication method instead of Service Principal authentication. The workflow has been updated to:

1. Extract Service Principal credentials from the `AZURE_CREDENTIALS` secret
2. Pass these credentials to Terraform as environment variables
3. Configure the backend to use these environment variables for authentication

If you're running Terraform locally, you need to set these environment variables manually:
```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
terraform init
```

#### Backend.tf File Creation

If you encounter an error like:
```
./.github/scripts/setup_terraform_state.sh: line XX: ../infra/backend.tf: No such file or directory
```

This means the script couldn't find or create the `infra` directory. The workflow has been updated to:
1. Create the `infra` directory before running the setup script
2. Use absolute paths to ensure the backend.tf file is created in the correct location
3. Include fallback mechanisms to find the repository root in different environments

If you still encounter this issue, you can manually create the `infra` directory before running the workflow:
```bash
mkdir -p infra
```

#### Databricks Provider Authentication

If you encounter an error related to Databricks provider authentication:

```
Error: Unable to authenticate to Databricks: cannot configure default credentials
```

This means the Databricks provider couldn't authenticate. To resolve this:

1. Ensure the Databricks workspace has been created first
2. Generate a Databricks personal access token
3. Set the `DATABRICKS_HOST` and `DATABRICKS_TOKEN` environment variables in the workflow or as GitHub secrets

#### Tainting Issues

If you encounter issues with the tainting process:

```
Error: Resource not found
```

This means the resource address in the taint_resources.txt file doesn't match any resource in the Terraform state. To resolve this:

1. Check the resource address syntax
2. Run `terraform state list` to see all resources in the state
3. Ensure the resource exists in the state before trying to taint it 