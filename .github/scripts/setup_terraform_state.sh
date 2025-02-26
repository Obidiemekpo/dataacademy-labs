#!/bin/bash
set -e

# Get storage prefix from command line argument or use default
STORAGE_PREFIX=${1:-"dataacademy"}

# Variables
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="st${STORAGE_PREFIX}tfstate"
CONTAINER_NAME="tfstate"
LOCATION="uksouth"

# Validate storage account name
if [[ ${#STORAGE_ACCOUNT_NAME} -gt 24 ]]; then
    echo "Error: Storage account name '${STORAGE_ACCOUNT_NAME}' exceeds 24 characters."
    echo "Please use a shorter prefix."
    exit 1
fi

if [[ ! $STORAGE_ACCOUNT_NAME =~ ^[a-z0-9]*$ ]]; then
    echo "Error: Storage account name '${STORAGE_ACCOUNT_NAME}' contains invalid characters."
    echo "Only lowercase letters and numbers are allowed."
    exit 1
fi

echo "Using storage account name: ${STORAGE_ACCOUNT_NAME}"

# Check if resource group exists
echo "Checking if resource group exists..."
if ! az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
    echo "Resource group does not exist. Creating resource group..."
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
else
    echo "Resource group already exists."
fi

# Check if storage account exists
echo "Checking if storage account exists..."
if ! az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME &> /dev/null; then
    echo "Storage account does not exist. Creating storage account..."
    az storage account create \
        --name $STORAGE_ACCOUNT_NAME \
        --resource-group $RESOURCE_GROUP_NAME \
        --location $LOCATION \
        --sku Standard_LRS \
        --kind StorageV2 \
        --encryption-services blob
else
    echo "Storage account already exists."
fi

# Get storage account key
echo "Getting storage account key..."
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Check if container exists
echo "Checking if container exists..."
if ! az storage container show --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY &> /dev/null; then
    echo "Container does not exist. Creating container..."
    az storage container create \
        --name $CONTAINER_NAME \
        --account-name $STORAGE_ACCOUNT_NAME \
        --account-key $ACCOUNT_KEY
else
    echo "Container already exists."
fi

# Output Terraform backend configuration
echo "Terraform state storage account is ready."
echo "Use the following backend configuration in your Terraform files:"
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"terraform.tfstate\""
echo "  }"
echo "}"

# Create backend.tf file
# First, ensure the infra directory exists
INFRA_DIR="${GITHUB_WORKSPACE}/infra"
if [ ! -d "$INFRA_DIR" ]; then
    echo "Creating infra directory at $INFRA_DIR"
    mkdir -p "$INFRA_DIR"
fi

# Now create the backend.tf file
cat > "${INFRA_DIR}/backend.tf" << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "terraform.tfstate"
  }
}
EOF

echo "Created backend.tf file in the infra directory at ${INFRA_DIR}/backend.tf" 