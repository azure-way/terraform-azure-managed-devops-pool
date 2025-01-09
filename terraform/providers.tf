terraform {
  required_version = ">= 1.9"
  required_providers {
    # azapi = {
    #   source  = "azure/azapi"
    #   version = "~> 1.14"
    # }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0.2"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "azurerm" { }  
}

# locals {
#   resource_providers_to_register = {
#     dev_center = {
#       resource_provider = "Microsoft.DevCenter"
#     }
#     devops_infrastructure = {
#       resource_provider = "Microsoft.DevOpsInfrastructure"
#     }
#   }
# }


provider "azuredevops" {
  org_service_url = local.azure_devops_organization_url

  client_id     = var.spn-client-id
  client_secret = var.spn-client-secret
  tenant_id     = var.spn-tenant-id
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription-id
  client_id       = var.spn-client-id
  client_secret   = var.spn-client-secret
  tenant_id       = var.spn-tenant-id
}