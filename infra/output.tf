output "AZURE_LOCATION" {
  value = var.location
}
output "AZURE_RESOURCE_GROUP" {
  value = var.resource_group_name
}
output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value = module.container_registry.container_registry_login_server
}