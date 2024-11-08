terraform {
  required_providers {
    azurerm = {
      version = "4.9.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.28"
    }
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy AI serach_service
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "search_service_name" {
  name          = var.resource_token
  resource_type = "azurerm_search_service"
  random_length = 0
  clean_input   = true
}

resource "azurerm_search_service" "search" {
  name                          = azurecaf_name.search_service_name.result
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  public_network_access_enabled = var.public_network_access_enabled
}

module "private_endpoint" {
  count                          = var.subnet_id != "" ? 1 : 0
  source                         = "../private_endpoint"
  name                           = azurerm_search_service.search.name
  resource_group_name            = var.resource_group_name
  tags                           = var.tags
  resource_token                 = var.resource_token
  private_connection_resource_id = azurerm_search_service.search.id
  location                       = var.location
  subnet_id                      = var.subnet_id
  subresource_names              = ["searchService"]
  is_manual_connection           = false
}
