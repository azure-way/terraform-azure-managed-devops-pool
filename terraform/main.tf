locals {
  azure_devops_organization_url = "https://dev.azure.com/${var.azure_devops_organization_name}"
}

data "azurerm_client_config" "this" {}

resource "random_pet" "name" {
  length  = 1
}

resource "azurerm_resource_group" "this" {
  location = var.region
  name     = "rg-${random_pet.name.id}"
}

resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${random_pet.name.id}-law"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_definition" "this" {
  name        = "Virtual Network Contributor for DevOpsInfrastructure (${random_pet.name.id})"
  scope       = azurerm_resource_group.this.id
  description = "Custom Role for Virtual Network Contributor for DevOpsInfrastructure (${random_pet.name.id})"

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
  name                = "${random_pet.name.id}-pip"
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "this" {
  location            = azurerm_resource_group.this.location
  name                = "${random_pet.name.id}-nat"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

resource "azurerm_virtual_network" "this" {
  name                = "${random_pet.name.id}-vnet"
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

data "azuredevops_agent_queue" "this" {
  project_id = var.ado_project_id
  name       = module.managed_devops_pool.name
  depends_on = [module.managed_devops_pool]
}

data "azuredevops_build_definition" "example" {
  project_id = var.ado_project_id
  name = var.azure_devops_build_definition_name
}

resource "azuredevops_pipeline_authorization" "this" {
  for_each = toset(var.pipeline_ids)
  project_id  = var.ado_project_id
  resource_id = data.azuredevops_agent_queue.this.id
  type        = "queue"
  pipeline_id = each.key
}

resource "azurerm_dev_center" "this" {
  location            = azurerm_resource_group.this.location
  name                = "dc-${random_pet.name.id}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_dev_center_project" "this" {
  dev_center_id       = azurerm_dev_center.this.id
  location            = azurerm_resource_group.this.location
  name                = "dcp-${random_pet.name.id}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "time_sleep" "wait_1_minute" {
  create_duration = "1m"
  
  depends_on = [azurerm_role_assignment.reader, azurerm_role_assignment.subnet_join]
}

# This is the module call
module "managed_devops_pool" {
  source  = "Azure/avm-res-devopsinfrastructure-pool/azurerm"
  version = "0.2.2"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = azurerm_resource_group.this.location
  name                           = "azure-way-mdp"
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

  depends_on = [time_sleep.wait_1_minute]
}

