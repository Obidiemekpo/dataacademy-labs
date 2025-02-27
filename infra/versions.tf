terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.67.0"
    }
  }
  required_version = ">= 1.0.0"
} 