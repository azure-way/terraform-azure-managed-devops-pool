output "managed_devops_pool_id" {
  value = module.managed_devops_pool.resource_id
}

output "managed_devops_pool_name" {
  value = module.managed_devops_pool.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "virtual_network_subnet" {
  value = azurerm_subnet.this.id
}