locals {
  azure_devops_organization_url = "https://dev.azure.com/${var.azure_devops_organization_name}"
}

data "azurerm_client_config" "this" {}

resource "random_string" "name" {
  length  = 6
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  location = var.region
  name     = "rg-${random_string.name.result}"
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${random_string.name.result}-law"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_definition" "this" {
  name        = "Virtual Network Contributor for DevOpsInfrastructure (${random_string.name.result})"
  scope       = azurerm_resource_group.this.id
  description = "Custom Role for Virtual Network Contributor for DevOpsInfrastructure (${random_string.name.result})"

  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/serviceAssociationLinks/validate/action",
      "Microsoft.Network/virtualNetworks/subnets/serviceAssociationLinks/write",
      "Microsoft.Network/virtualNetworks/subnets/serviceAssociationLinks/delete"
    ]
  }
}

data "azuread_service_principal" "this" {
  display_name = "DevOpsInfrastructure" # This is a special built in service principal (see: https://learn.microsoft.com/en-us/azure/devops/managed-devops-pools/configure-networking?view=azure-devops&tabs=azure-portal#to-check-the-devopsinfrastructure-principal-access)
}

resource "azurerm_public_ip" "this" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.this.location
  name                = "${random_string.name.result}-pip"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${random_string.name.result}-nat"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

resource "azurerm_virtual_network" "this" {
  name                = "${random_string.name.result}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.address_space
}

resource "azurerm_subnet" "this" {
  name                 = "managed-pool-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.subnet_address_prefixes

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.DevOpsInfrastructure/pools"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  subnet_id      = azurerm_subnet.this.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_role_assignment" "reader" {
  principal_id         = data.azuread_service_principal.this.object_id
  role_definition_name = "Reader"
  scope                = azurerm_virtual_network.this.id

}

resource "azurerm_role_assignment" "subnet_join" {
  principal_id       = data.azuread_service_principal.this.object_id
  role_definition_id = azurerm_role_definition.this.role_definition_resource_id
  scope              = azurerm_virtual_network.this.id

}

# module "virtual_network" {
#   source              = "Azure/avm-res-network-virtualnetwork/azurerm"
#   version             = "0.4.0"
#   address_space       = ["10.30.0.0/16"]
#   location            = azurerm_resource_group.this.location
#   name                = "vnet-${random_string.name.result}"
#   resource_group_name = azurerm_resource_group.this.name
#   role_assignments = {
#     virtual_network_reader = {
#       role_definition_id_or_name = "Reader"
#       principal_id               = data.azuread_service_principal.this.object_id
#     }
#     subnet_join = {
#       role_definition_id_or_name = azurerm_role_definition.this.role_definition_resource_id
#       principal_id               = data.azuread_service_principal.this.object_id
#     }
#   }
#   subnets = {
#     subnet0 = {
#       name             = "subnet-${random_string.name.result}"
#       address_prefixes = ["10.30.0.0/24"]
#       delegation = [{
#         name = "Microsoft.DevOpsInfrastructure.pools"
#         service_delegation = {
#           name = "Microsoft.DevOpsInfrastructure/pools"
#         }
#       }]
#       nat_gateway = {
#         id = azurerm_nat_gateway.this.id
#       }
#     }
#   }
#   enable_telemetry = var.enable_telemetry
# }

resource "azurerm_dev_center" "this" {
  location            = azurerm_resource_group.this.location
  name                = "dc-${random_string.name.result}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_dev_center_project" "this" {
  dev_center_id       = azurerm_dev_center.this.id
  location            = azurerm_resource_group.this.location
  name                = "dcp-${random_string.name.result}"
  resource_group_name = azurerm_resource_group.this.name
}

# This is the module call
module "managed_devops_pool" {
  source  = "Azure/avm-res-devopsinfrastructure-pool/azurerm"
  version = "0.2.2"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = azurerm_resource_group.this.location
  name                           = "mdp-${random_string.name.result}"
  dev_center_project_resource_id = azurerm_dev_center_project.this.id
  subnet_id                      = azurerm_subnet.this.id
  maximum_concurrency            = var.maximum_concurrency
  organization_profile = {
    organizations = [{
      name     = var.azure_devops_organization_name
      projects = var.azure_devops_project_names
    }]
  }
  fabric_profile_images = [
    {
      well_known_image_name = "ubuntu-20.04/latest"
      aliases = [
        "ubuntu-20.04/latest",
        "ubuntu-20.04"
      ]
    },
    {
      well_known_image_name = "ubuntu-22.04/latest"
      aliases = [
        "ubuntu-22.04/latest",
        "ubuntu-22.04"
      ]
    },
    {
      well_known_image_name = "windows-2019/latest"
      aliases = [
        "windows-2019/latest",
        "windows-2019"
      ]
    },
    {
      well_known_image_name = "windows-2022/latest"
      aliases = [
        "windows-2022/latest",
        "windows-2022"
      ]
    }
  ]
  enable_telemetry = var.enable_telemetry

  depends_on = [azurerm_role_assignment.reader, azurerm_role_assignment.subnet_join]
}

