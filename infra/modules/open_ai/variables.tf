variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}

variable "subnet_id" {
  description = "The resource id of the subnet to deploy the private endpoint into"
  type        = string
}

variable "user_assigned_identity_object_id" {
  description = "The object id of the user assigned identity"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The id of the Log Analytics workspace to send logs to"
  type        = string
}

variable "public_network_access_enabled" {
  description = "Whether or not public network access is enabled"
  type        = bool
}