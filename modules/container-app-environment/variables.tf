variable "name" {
  description = "Name of the Container App Environment."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the environment."
  type        = string
}

variable "location" {
  description = "Azure region for the environment."
  type        = string
}

variable "uami_id" {
  description = "Resource ID of the user assigned identity attached to the environment."
  type        = string
}

variable "infrastructure_subnet_id" {
  description = <<-EOT
    Resource ID of the subnet for VNet integration.
    Required when internal_load_balancer_enabled = true.
    The subnet must be at least /27 and delegated to Microsoft.App/environments.
  EOT
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "Whether the environment uses an internal load balancer. Requires infrastructure_subnet_id."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the environment."
  type        = map(string)
  default     = {}
}
