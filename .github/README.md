# GitHub Workflow for Terraform Deployment

This directory contains GitHub workflow configurations for automating the deployment of Terraform infrastructure.

## Workflow: Terraform Deploy

The `terraform-deploy.yml` workflow automates the deployment of Azure resources using Terraform. It performs the following steps:

1. Sets up a storage account for Terraform state if it doesn't exist
2. Initializes Terraform
3. Validates the Terraform configuration
4. Plans the deployment (for pull requests)
5. Applies the changes (for pushes to main branch)

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

## Terraform State Storage

The workflow automatically creates a storage account for Terraform state if it doesn't exist. The storage account details are:

- Resource Group: `rg-terraform-state`
- Storage Account: `st<prefix>tfstate` (where `<prefix>` is customizable)
- Container: `tfstate`
- Location: `uksouth`

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
- `.github/scripts/setup_terraform_state.sh`: Script to set up the Terraform state storage account

## Troubleshooting

If you encounter issues with the workflow:

1. Check the workflow run logs in GitHub Actions
2. Verify that the Service Principal has the correct permissions
3. Ensure that the `AZURE_CREDENTIALS` secret is correctly formatted
4. Check if the storage account name is globally unique
5. If you get an error about the storage account name being too long or containing invalid characters, try a shorter or simpler prefix 