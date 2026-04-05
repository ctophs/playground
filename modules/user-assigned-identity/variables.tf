variable "name" {
  description = "Name of the user assigned identity."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the identity."
  type        = string
}

variable "location" {
  description = "Azure region for the identity."
  type        = string
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
  default     = {}
}
