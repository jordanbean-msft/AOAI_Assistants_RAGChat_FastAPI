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

data "azurerm_client_config" "current" {}
# ------------------------------------------------------------------------------------------------------
# DEPLOY AZURE KEYVAULT
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "kv_name" {
  name          = var.resource_token
  resource_type = "azurerm_key_vault"
  random_length = 0
  clean_input   = true
}

resource "azurerm_key_vault" "kv" {
  name                            = azurecaf_name.kv_name.result
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled        = false
  sku_name                        = "standard"
  tags                            = var.tags
  public_network_access_enabled   = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = false
}

resource "azurerm_key_vault_secret" "secrets" {
  count        = length(var.secrets)
  name         = var.secrets[count.index].name
  value        = var.secrets[count.index].value
  key_vault_id = azurerm_key_vault.kv.id
}

module "private_endpoint" {
  count                          = var.subnet_id != "" ? 1 : 0
  source                         = "../private_endpoint"
  name                           = azurerm_key_vault.kv.name
  resource_group_name            = var.resource_group_name
  tags                           = var.tags
  resource_token                 = var.resource_token
  private_connection_resource_id = azurerm_key_vault.kv.id
  location                       = var.location
  subnet_id                      = var.subnet_id
  subresource_names              = ["vault"]
  is_manual_connection           = false
}

resource "azurerm_key_vault_access_policy" "app" {
  count        = length(var.access_policy_object_ids)
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.access_policy_object_ids[count.index]

  secret_permissions = [
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "user" {
  count        = var.principal_id == "" ? 0 : 1
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.principal_id

  secret_permissions = [
    "Get",
    "Set",
    "List",
    "Delete",
    "Purge"
  ]
}