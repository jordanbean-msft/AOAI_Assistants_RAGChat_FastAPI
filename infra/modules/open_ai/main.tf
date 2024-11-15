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
# Deploy cognitive services
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "cognitiveservices_name" {
  name          = "openai-${var.resource_token}"
  resource_type = "azurerm_cognitive_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cognitive_account" "cognitive_account" {
  name                          = azurecaf_name.cognitiveservices_name.result
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = "S0"
  custom_subdomain_name         = azurecaf_name.cognitiveservices_name.result
  public_network_access_enabled = var.public_network_access_enabled
}

resource "azurerm_cognitive_deployment" "chat" {
  name                 = "chat"
  cognitive_account_id = azurerm_cognitive_account.cognitive_account.id
  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = "2024-05-13"
  }
  sku {
    name = "Standard"
    capacity = 40
  }
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "embedding"
  cognitive_account_id = azurerm_cognitive_account.cognitive_account.id
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }
  sku {
    name = "Standard"
    capacity = 40
  }
}

# module "private_endpoint" {
#   for_each                       = { for deployment in var.openai_model_deployments : deployment.name_suffix => deployment }
#   source                         = "../private_endpoint"
#   name                           = azurerm_cognitive_account.cognitive_account[each.key].name
#   resource_group_name            = var.resource_group_name
#   tags                           = var.tags
#   resource_token                 = var.resource_token
#   private_connection_resource_id = azurerm_cognitive_account.cognitive_account[each.key].id
#   location                       = each.value.location
#   subnet_id                      = var.subnet_id
#   subresource_names              = ["account"]
#   is_manual_connection           = false
# }

resource "azurerm_monitor_diagnostic_setting" "openai_logging" {
  name                       = "openai-logging"
  target_resource_id         = azurerm_cognitive_account.cognitive_account.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "RequestResponse"
  }

  metric {
    category = "AllMetrics"
  }
}