locals {
  tags                             = { azd-env-name : var.environment_name }
  sha                              = base64encode(sha256("${var.location}${data.azurerm_client_config.current.subscription_id}${var.resource_group_name}"))
  resource_token                   = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  #app_subnet_nsg_name              = "nsg-${var.network.apim_subnet_name}-subnet"
  #private_endpoint_subnet_nsg_name = "nsg-${var.network.private_endpoint_subnet_name}-subnet"
  api_container_app_name           = "api"
  web_container_app_name           = "web"
  default_container_app_image_name = "mcr.microsoft.com/k8se/quickstart:latest"
  api_container_app_image_name     = coalesce(var.service_api_image_name, local.default_container_app_image_name)
  web_container_app_image_name     = coalesce(var.service_web_image_name, local.default_container_app_image_name)
  container_registry_admin_password_secret_name = "container-registry-admin-password"
  azure_openai_secret_name                      = "azure-openai-key"
  azure_cognitive_services_secret_name          = "azure-cognitive-services-key"
  azure_search_service_secret_name              = "azure-search-service-apikey"
}

# ------------------------------------------------------------------------------------------------------
# Deploy virtual network
# ------------------------------------------------------------------------------------------------------

/*module "virtual_network" {
  source               = "./modules/virtual_network"
  location             = var.location
  resource_group_name  = var.network.virtual_network_resource_group_name
  tags                 = local.tags
  resource_token       = local.resource_token
  virtual_network_name = var.network.virtual_network_name
  subnets = [
    {
      name               = var.network.apim_subnet_name
      address_prefixes   = var.network.apim_subnet_address_prefixes
      service_delegation = false
      delegation_name    = ""
      actions            = [""]
      network_security_rules = [
        {
          name                       = "AllowManagementEndpointForAzurePortalAndPowerShell"
          priority                   = 120
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [3443]
          source_address_prefix      = "ApiManagement"
          destination_address_prefix = "VirtualNetwork"
        },
        {
          name                       = "AllowAzureInfrastructureLoadBalancer"
          priority                   = 130
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [6390, 6391]
          source_address_prefix      = "AzureLoadBalancer"
          destination_address_prefix = "VirtualNetwork"
        },
        {
          name                       = "AllowSyncCountersForRateLimitPoliciesBetweenMachines"
          priority                   = 140
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Udp"
          source_port_range          = "*"
          destination_port_ranges    = [4290]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "VirtualNetwork"
        },
        {
          name                       = "AllowExternalRedisCacheInbound"
          priority                   = 150
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [6380]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "VirtualNetwork"
        },
        {
          name                       = "AllowDependencyOnAzureStorageForCoreServiceFunctionality"
          priority                   = 120
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [443]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "Storage"
        },
        {
          name                       = "AllowAccessToEntraIdMicrosoftGraphAndAzureKeyVault"
          priority                   = 130
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [443]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "AzureActiveDirectory"
        },
        {
          name                       = "AllowAccessToAzureSQLEndpointsForCoreServiceFunctionality"
          priority                   = 140
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [1433]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "SQL"
        },
        {
          name                       = "AllowAccessToAzureKeyVaultForCoreServiceFunctionality"
          priority                   = 150
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [443]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "AzureKeyVault"
        },
        {
          name                       = "AllowLogToEventHub"
          priority                   = 160
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [5671, 5672, 443]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "EventHub"
        },
        {
          name                       = "AllowPublishDiagnosticLogsAndMetricsResourceHealthAndApplicationInsights"
          priority                   = 170
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [1886, 443]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "AzureMonitor"
        },
        {
          name                       = "AllowExternalRedisCacheOutbound"
          priority                   = 180
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_ranges    = [6380]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "VirtualNetwork"
        }
      ]
    },
    {
      name                   = var.network.private_endpoint_subnet_name
      address_prefixes       = var.network.private_endpoint_subnet_address_prefixes
      service_delegation     = false
      delegation_name        = ""
      actions                = []
      network_security_rules = []
    },
    {
      name                   = var.network.function_app_subnet_name
      address_prefixes       = var.network.function_app_subnet_address_prefixes
      service_delegation     = false
      delegation_name        = ""
      actions                = []
      network_security_rules = []
    }
  ]
  api_management_subnet_name   = var.network.apim_subnet_name
  private_endpoint_subnet_name = var.network.private_endpoint_subnet_name
  ai_studio_subnet_name        = var.network.ai_studio_subnet_name
  function_app_subnet_name     = var.network.function_app_subnet_name
  subscription_id              = data.azurerm_client_config.current.subscription_id
  firewall_ip_address          = var.network.firewall_ip_address
}*/

# ------------------------------------------------------------------------------------------------------
# Deploy application insights
# ------------------------------------------------------------------------------------------------------
module "application_insights" {
  source              = "./modules/application_insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = module.log_analytics.log_analytics_workspace_id
  tags                = local.tags
  resource_token      = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy log analytics
# ------------------------------------------------------------------------------------------------------
module "log_analytics" {
  source              = "./modules/log_analytics"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  resource_token      = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy managed identity
# ------------------------------------------------------------------------------------------------------
module "managed_identity" {
  source              = "./modules/managed_identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  resource_token      = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy key vault
# ------------------------------------------------------------------------------------------------------
module "key_vault" {
  source              = "./modules/key_vault"
  location            = var.location
  principal_id        = var.principal_id
  resource_group_name = var.resource_group_name
  tags                = local.tags
  resource_token      = local.resource_token
  access_policy_object_ids = [
    module.managed_identity.user_assigned_identity_object_id
  ]
  secrets = [
    {
      name  = local.container_registry_admin_password_secret_name
      value = module.container_registry.container_registry_admin_password
    },
     {
      name  = local.azure_openai_secret_name
      value = module.openai.azure_cognitive_services_key
    },
    {
      name  = local.azure_cognitive_services_secret_name
      value = module.document_intelligence.azure_cognitive_services_key
    },
    {
      name  = local.azure_search_service_secret_name
      value = module.search_service.azure_search_service_apikey
    }
  ]
  subnet_id = "" #module.virtual_network.private_endpoint_subnet_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy OpenAI
# ------------------------------------------------------------------------------------------------------
module "openai" {
  source                           = "./modules/open_ai"
  location                         = var.location
  resource_group_name              = var.resource_group_name
  resource_token                   = local.resource_token
  tags                             = local.tags
  subnet_id                        = "" #module.virtual_network.private_endpoint_subnet_id
  user_assigned_identity_object_id = module.managed_identity.user_assigned_identity_object_id
  log_analytics_workspace_id       = module.log_analytics.log_analytics_workspace_id
  public_network_access_enabled = true
}

# ------------------------------------------------------------------------------------------------------
# Deploy Storage Account
# ------------------------------------------------------------------------------------------------------

module "storage_account" {
  source                        = "./modules/storage_account"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = "" #module.virtual_network.private_endpoint_subnet_id
  account_tier                  = var.storage_account.tier
  account_replication_type      = var.storage_account.replication_type
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy Container Registry
# ------------------------------------------------------------------------------------------------------

module "container_registry" {
  source                        = "./modules/container_registry"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = "" #module.virtual_network.private_endpoint_subnet_id
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy Document Intelligence
# ------------------------------------------------------------------------------------------------------

module "document_intelligence" {
  source                        = "./modules/document_intelligence"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = "" #module.virtual_network.private_endpoint_subnet_id
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
  public_network_access_enabled = true
}

# ------------------------------------------------------------------------------------------------------
# Deploy Search Service
# ------------------------------------------------------------------------------------------------------

module "search_service" {
  source                        = "./modules/search_service"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = "" #module.virtual_network.private_endpoint_subnet_id
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
  public_network_access_enabled = true
}

# ------------------------------------------------------------------------------------------------------
# Deploy Container Apps Environment
# ------------------------------------------------------------------------------------------------------

module "container_app_environment" {
  source                                     = "./modules/container_app_environment"
  location                                   = var.location
  resource_group_name                        = var.resource_group_name
  tags                                       = local.tags
  resource_token                             = local.resource_token
  app_insights_connection_string             = module.application_insights.application_insights_connection_string
  container_apps_environment_subnet_id       = "" #module.virtual_network.private_endpoint_subnet_id
  file_share_name                            = module.storage_account.file_share_name
  log_analytics_workspace_id                 = module.log_analytics.log_analytics_workspace_id
  log_analytics_workspace_customer_id        = module.log_analytics.log_analytics_workspace_customer_id
  log_analytics_workspace_primary_shared_key = module.log_analytics.log_analytics_workspace_primary_shared_key
  storage_account_name                       = module.storage_account.storage_account_name
  storage_account_access_key                 = module.storage_account.storage_account_access_key
}

# ------------------------------------------------------------------------------------------------------
# Deploy Container Apps
# ------------------------------------------------------------------------------------------------------

module "api_container_app" {
  source                          = "./modules/container_app"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tags                            = local.tags
  resource_token                  = local.resource_token
  container_app_environment_id    = module.container_app_environment.container_app_environment_id
  log_analytics_workspace_id      = module.log_analytics.log_analytics_workspace_id
  container_registry_login_server = module.container_registry.container_registry_login_server
  container_registry_admin_username = module.container_registry.container_registry_admin_username
  container_registry_admin_password_secret_name = local.container_registry_admin_password_secret_name
  managed_identity_resource_id    = module.managed_identity.user_assigned_identity_id
  container_apps = [
    {
      name                  = local.api_container_app_name
      tags                  = { "azd-service-name" : local.api_container_app_name }
      revision_mode         = "Single"
      workload_profile_name = module.container_app_environment.workload_profile_name
      ingress = {
        external_enabled = true
        target_port      = 3100
        transport        = "http"
        traffic_weight = [
          {
            label           = "blue"
            latest_revision = true
            percentage      = 100
          }
        ]
      }
      secrets = [
         {
          name                = local.azure_openai_secret_name,
          identity            = module.managed_identity.user_assigned_identity_id
          key_vault_secret_id = "${module.key_vault.azure_key_vault_endpoint}secrets/${local.azure_openai_secret_name}"
        },
        {
          name                = local.container_registry_admin_password_secret_name,
          identity            = module.managed_identity.user_assigned_identity_id
          key_vault_secret_id = "${module.key_vault.azure_key_vault_endpoint}secrets/${local.container_registry_admin_password_secret_name}"
        },
        {
          name                = local.azure_search_service_secret_name,
          identity            = module.managed_identity.user_assigned_identity_id
          key_vault_secret_id = "${module.key_vault.azure_key_vault_endpoint}secrets/${local.azure_search_service_secret_name}"
        }
      ]
      identity = {
        type         = "UserAssigned"
        identity_ids = [module.managed_identity.user_assigned_identity_id]
      }
      template = {
        containers = [
          {
            name   = local.api_container_app_name
            image  = local.api_container_app_image_name
            cpu    = 4
            memory = "16Gi"
            env = concat([
              {
                name        = "AOAI_KEY"
                secret_name = local.azure_openai_secret_name
              },
              {
                name = "AI_SEARCH_KEY"
                secret_name = local.azure_search_service_secret_name
              },
              {
                name = "AI_SEARCH_ENDPOINT"
                value = module.search_service.azure_search_service_endpoint
              },
              {
                name = "AI_SEARCH_INDEX"
                value = var.ai_search.index_name
              },
              {
                name = "AOAI_ASSISTANT_ID"
                value = var.openai.assistant_id
              },
              {
                name  = "AOAI_ENDPOINT"
                value = module.openai.azure_cognitive_services_endpoint
              },
              {
                name  = "AZURE_OPENAI_API_VERSION"
                value = "2024-05-01-preview"
              },
              {
                name  = "AOAI_EMBEDDINGS_MODEL"
                value = "text-embedding-3-large"
              },
              {
                name  = "OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED"
                value = "true"
              },
              {
                name  = "OTEL_SERVICE_NAME"
                value = "aoai-assistants-ragchat-fastapi"
              },
              {
                name  = "OTEL_PYTHON_FASTAPI_EXCLUDED_URLS"
                value = "readiness,liveness,startup"
              }
            ])
            # liveness_probe = {
            #   initial_delay    = 30
            #   interval_seconds = 30
            #   path             = "/_stcore/health"
            #   port             = 8000
            #   timeout          = 1
            #   transport        = "HTTP"
            # }
            # readiness_probe = {
            #   interval_seconds = 30
            #   path             = "/_stcore/health"
            #   port             = 8000
            #   timeout          = 1
            #   transport        = "HTTP"
            # }
            # startup_probe = {
            #   interval_seconds = 10
            #   path             = "/_stcore/health"
            #   port             = 8000
            #   timeout          = 1
            #   transport        = "HTTP"
            # }
          }
        ]
        http_scale_rule = [
          {
            name                = "http-scaler"
            concurrent_requests = 10
          }
        ]
        min_replicas = 1
        max_replicas = 1
      }
    }
  ]
}

module "web_container_app" {
  source                          = "./modules/container_app"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tags                            = local.tags
  resource_token                  = local.resource_token
  container_app_environment_id    = module.container_app_environment.container_app_environment_id
  log_analytics_workspace_id      = module.log_analytics.log_analytics_workspace_id
  container_registry_login_server = module.container_registry.container_registry_login_server
  container_registry_admin_username = module.container_registry.container_registry_admin_username
  container_registry_admin_password_secret_name = local.container_registry_admin_password_secret_name
  managed_identity_resource_id    = module.managed_identity.user_assigned_identity_id
  container_apps = [
    {
      name                  = local.web_container_app_name
      tags                  = { "azd-service-name" : local.web_container_app_name }
      revision_mode         = "Single"
      workload_profile_name = module.container_app_environment.workload_profile_name
      ingress = {
        external_enabled = true
        target_port      = 8501
        transport        = "http"
        traffic_weight = [
          {
            label           = "blue"
            latest_revision = true
            percentage      = 100
          }
        ]
      }
      secrets = [
        {
          name                = local.container_registry_admin_password_secret_name,
          identity            = module.managed_identity.user_assigned_identity_id
          key_vault_secret_id = "${module.key_vault.azure_key_vault_endpoint}secrets/${local.container_registry_admin_password_secret_name}"

        }
      ]
      identity = {
        type         = "UserAssigned"
        identity_ids = [module.managed_identity.user_assigned_identity_id]
      }
      template = {
        containers = [
          {
            name   = local.web_container_app_name
            image  = local.web_container_app_image_name
            cpu    = 4
            memory = "16Gi"
            env = concat([
              {
                name = "API_BASE_URL"
                value = "https://${module.api_container_app.container_apps[local.api_container_app_name].ingress[0].fqdn}"
              }
            ])
            liveness_probe = {
              initial_delay    = 30
              interval_seconds = 30
              path             = "/_stcore/health"
              port             = 8000
              timeout          = 1
              transport        = "HTTP"
            }
            readiness_probe = {
              interval_seconds = 30
              path             = "/_stcore/health"
              port             = 8000
              timeout          = 1
              transport        = "HTTP"
            }
            startup_probe = {
              interval_seconds = 10
              path             = "/_stcore/health"
              port             = 8000
              timeout          = 1
              transport        = "HTTP"
            }
          }
        ]
        http_scale_rule = [
          {
            name                = "http-scaler"
            concurrent_requests = 10
          }
        ]
        min_replicas = 1
        max_replicas = 1
      }
    }
  ]
}