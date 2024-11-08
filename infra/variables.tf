variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "principal_id" {
  description = "The Id of the azd service principal to add to deployed keyvault access policies"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "RG for the deployment"
  type        = string
}

variable "environment_name" {
  description = "The name of the environment"
  type        = string
}

variable "network" {
  type = object({
    virtual_network_resource_group_name      = string
    virtual_network_name                     = string
    private_endpoint_subnet_name             = string
    private_endpoint_subnet_address_prefixes = list(string)
    app_subnet_name                          = string
    app_subnet_address_prefixes              = list(string)
  })
}

variable "openai" {
  type = object({
    assistant_id = string
  })
}

variable "storage_account" {
  type = object({
    tier             = string
    replication_type = string
  })
}

variable "ai_search" {
  type = object({
    index_name = string
  })
}

variable "service_api_image_name" {
  description = "The name of the service api image"
  type        = string
}

variable "service_web_image_name" {
  description = "The name of the service web image"
  type        = string
}